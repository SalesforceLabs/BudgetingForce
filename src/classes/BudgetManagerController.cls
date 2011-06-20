/*
Copyright (c) 2011, salesforce.com, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation 
    and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com, Inc. nor the names of its contributors 
    may be used to endorse or promote products derived from this software 
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
OF THE POSSIBILITY OF SUCH DAMAGE.

*/

/* This class provides the framework for implementing budgets.
 * The basic flow is: 
 *    (a) logic to create the tree of nodes
 *    (b) Use addNode method to add nodes to the tree
 *    (b) Use save method to save the nodes of the tree to the database
 *
 * @since 2010-04
 */

public with sharing class BudgetManagerController {
	
	public BudgetNode tree {get; set;} 
	public Map<Integer, BudgetNode> budgetNodesMap {get;set;}
	public List<SelectOption> periodsList {get; set;}
	public List<SelectOption> budgetAreaList {get; set;}
	public List<SelectOption> regionsList {get; set;}
	public List<SelectOption> departmentsList {get;set;}
	public List<SelectOption> planBudgetCodesList {get;set;}
	public List<SelectOption> pbBudgetOwnersList {get;set;}
	public List<SelectOption> recurringList {get;set;}
	public List<SelectOption> v2MomMethodsList {get;set;}
	public List<selectOption> cloudsList {get;set;}
	public List<String> currentBudgetArea {get; set;}
	public String currentPeriod {get; set;}	
	public String newBudgetNodeName{get;set;}
	public String parentNode{get;set;}
	public String errorMsg {get; set;}
	public String level1BudgetPeriod {get; set;}
	public String level1BudgetArea {get; set;}
	public String level3BudgetShortName {get; set;}
	public String level3BudgetOwner {get; set;}
	public String level3BudgetPlanBudget {get;set;}
	public String level4BudgetShortName {get;set;}
	public String level4BudgetRegion {get;set;} 
	public String level4BudgetDepartment {get;set;}
	public String level4BudgetV2MomMethod {get;set;}
	public String level4BudgetCloud {get;set;}
	public String level4BudgetDescription {get;set;}
	public String level4BudgetLineAmount {get;set;}
	public Boolean wasManageBudgetsClicked {get;set;}
	public Boolean readOnly {get; set;}
	public Integer installFailed{get;set;}
	public BudgetPeriodUtility bpu{get;set;}
	public Boolean isUserAllowed {get;set;}
		
	public Integer i = 1;

	public String budgetId {get;set;}
	public String budgetLevel {get;set;}

	public String note1{
		get{
			return ReclaimBudgetCS__c.getInstance() != null ? ReclaimBudgetCS__c.getInstance().ManagerNoteInUI1__c : '';
		}
	}
	
	public String note2{
		get{
			return ReclaimBudgetCS__c.getInstance() != null ? ReclaimBudgetCS__c.getInstance().ManagerNoteInUI2__c : '';
		}	
	}
		
	private static final String BUDGET_OWNER     = 'budgetOwner';
	private static final String PROGRAM_BUDGET   = 'programBudget'; 
	private static final String BUDGET_LINE      = 'budgetLine';
	private static final String PURCHASE_REQUEST = 'purchaseRequest';
	private static final String CONTINGENCY = 'CONTINGENCY';
	
	private static final String DOMAIN_HOST = ''; //Label.DomainHost;

			
	public BudgetManagerController(){
		init();	
	}
	
	public void init() {
		installFailed = 0;
		bpu = new BudgetPeriodUtility();
		loadAllLists();
		initializeVariables();
		createTree(createFilterBy());
		
		// If budgetId is != null and != '' then I reset currentPeriod and currentBudgetArea because I only have one Budgets__c so I don't need to display all the periods,
		// neither all the Budget Areas
		if (budgetId != null && budgetId != '') {
			resetCurrentPeriodAndArea();
		}						
		tree.resetAmounts();	
	}
	
	public void install(){
		try{
			bpu.createPeriodsForCurrentYear();
			installFailed = 1;
		}
		catch(BudgetException e){
			installFailed = 2;
		}
	}
	
	/*
	 * Method: createFilterBy()
	 * Generates the filterBy string
	 */
	public String createFilterBy() {
		String filterBy = '';
		// If We have a budgetId != null && != '' then only create the tree for the Budget Owner on which the Id is budgetId 
		if ((budgetId != null) && (budgetId != '') && (budgetLevel != null) && (budgetLevel != '')) {
			wasManageBudgetsClicked = true;
			if (budgetLevel == BUDGET_OWNER) {
				filterBy = 'WHERE Id = \'' + String.escapeSingleQuotes(budgetId) + '\'';
			} else if (budgetLevel == PROGRAM_BUDGET || budgetLevel == BUDGET_LINE || budgetLevel == PURCHASE_REQUEST) {
				filterBy = 'WHERE Id = \'' + String.escapeSingleQuotes(getParentId(budgetId, budgetLevel)) + '\'';
			}	
		} else {
			wasManageBudgetsClicked = false;
			filterBy = 'WHERE Period__c = \'' + String.escapeSingleQuotes(currentPeriod) + '\'' + ' AND Budget_Area__c in : currentBudgetArea';
		}	
		return filterBy;
	}	
	/*
	 * Method: addNode()
	 * Adds a Budget Owner, Program Budget or Budget Line to the tree, depending on the ParentNode that we get from the page.
	 */		
	public void addNode() {
		// Check if we request to add a node to the first, second, or third level. 
		if (parentNode != null && parentNode != '') {
			Integer parentNodeId;
			try {
				parentNodeId = Integer.valueOf(parentNode);
			} catch (Exception e) {
				errorMsg = 'Invalid integer.';
			}
			
			if (!budgetNodesMap.isEmpty() && budgetNodesMap.containsKey(parentNodeId)) {
				BudgetNode bn = budgetNodesMap.get(parentNodeId);
				BudgetNode newBLNode;
				// Check if we request to add a node to the second, or third level.
				if (bn.Level == 1) {
					// New Program Budget
					Program_Budget__c newBL = new Program_Budget__c(Program_Type__c = level3BudgetPlanBudget,
																	Budget_Area__c = level3BudgetOwner,
																	Short_Name__c = level3BudgetShortName, 
																	Region__c = bn.Region,
																	Program_Budget_Amount__c = 0, 
																	Proposed_Budget__c = 0);
					// Program Budget name
					newBL.Name = bn.name + ': ' + level3BudgetPlanBudget + (level3BudgetShortName == '' ? '' : ': ' + level3BudgetShortName);	  
					newBLNode = new ProgramBudget(i++, newBL); 
				} else if (bn.Level == 2) {
					// New Budget Line 
					Budget_Line__c newBL = new Budget_Line__c(Short_Name__c = level4BudgetShortName, 
															  Region__c = level4BudgetRegion,
															  Department__c = level4BudgetDepartment,
															  Description__c = level4BudgetDescription,
															  Budget_Line_Amount__c = BudgetUtil.parseDecimal(level4BudgetLineAmount));
					// Budget Line name
					for (SelectOption so : periodsList) {
						if (currentPeriod == so.getValue()) {
								newBL.Name = so.getLabel() + ' ' + level4BudgetRegion + (level4BudgetShortName == '' ? '' : ': ' + level4BudgetShortName);
						}
					}											
					newBLNode = new BudgetLine(i++, newBL);
				}
				if (newBLNode != null) { 
					bn.add(newBLNode); // add a node to the Tree
					// set collapsed to false to display the hierarchy
					newBLNode.collapsed = false;
					if (newBLNode.parent != null) newBLNode.parent.collapsed = false;
					if (newBLNode.parent.parent != null) newBLNode.parent.parent.collapsed = false;
					addToMap(newBLNode.Id, newBLNode); // store the node in a Map so we can reference it later
				}				
			}
		} else {
			// New Budget Owner
			Budgets__c newBL = new Budgets__c(Period__c = level1BudgetPeriod, 
											  Budget_Area__c = level1BudgetArea,  
											  Budget_Amount__c = 0);
			for (SelectOption so : periodsList) {
				if (level1BudgetPeriod == so.getValue()) {
					// Budget Owner name
					newBL.Name = so.getLabel() + ' ' + level1BudgetArea;	
				}
			}
			
			BudgetNode newBLNode = new Budgets(i++, newBL);	 
			List<BudgetNode> auxList = new List<BudgetNode>(); // Utility list that will add the new node on top of the list.
			auxList.add(newBLNode);  
			auxList.addAll(tree.children); 
			addToMap(newBLNode.Id, newBLNode); 
			tree.children = auxList; 
		}
	}
	
	/*
	 * Method: saveTree()
	 * Invokes the save() method
	 */	
	public PageReference saveTree() {
		save(tree);
		return null;
	}
	
	/*
	 * Method: filterTree()
	 * Generates the filterBy String using currentPeriod and currentBudgetArea variables, values that we get from the page.
	 */	 
	public void filterTree() {    	

		String filterBy = '';
		
		if (currentPeriod != null && currentBudgetArea != null) {
			filterBy = 'WHERE Period__c = \'' + String.escapeSingleQuotes(currentPeriod) + '\'' + ' AND Budget_Area__c in : currentBudgetArea';
		}
		createTree(filterBy); // invokes to createTree passing on the filterBy that was generated.
		errorMsg = null; // set errorMsg to null so if there is an errorMsg from a previous call then it doesn't show up after the current call
    }

    public void changeReadOnly() {
    	readOnly = !readOnly;
    }
    
    /*
     * Method: save()
     * Saves the tree to the database
     */
    private void save(BudgetNode treeToSave) {
    	this.errorMsg = BudgetUtil.save(treeToSave);
    }
        
    /*
     * Method: loadAllLists()
     * Load all the lists with the corresponding values.

	 * GUS-Id : 799608
	 * Modified by: Santiago Doval 7/19/10
	 * Pending review: Pablo Vigil, Guillermo Freire, Diego Febles, Angelica Buffa 
     */
    private void loadAllLists() {

		periodsList = new List<SelectOption>();
		budgetAreaList = new List<SelectOption>();
		recurringList = new List<SelectOption>();
    
    	Schema.Describefieldresult picklistBudgetAreasSchema = Budgets__c.Budget_Area__c.getDescribe();
    	Schema.Describefieldresult picklistRegionsSchema = Program_Budget__c.Region__c.getDescribe();
    	Schema.Describefieldresult picklistPlanBudgetCodesSchema = Program_Budget__c.Program_Type__c.getDescribe();
    	Schema.Describefieldresult picklistPbBudgetOwnersSchema = Program_Budget__c.Budget_Area__c.getDescribe();
		Schema.Describefieldresult picklistDepartmentSchema = Budget_Line__c.Department__c.getDescribe();
		    	
    	// Adds periods to periodsList 
    	periodsList = bpu.getQuarterOptions();
    	
    	// Adds budget areas to budgetAreaList
    	for (Schema.Picklistentry iter : picklistBudgetAreasSchema.getPicklistValues()) {
    		if(iter.getValue() != CONTINGENCY){
    			budgetAreaList.add(new SelectOption(iter.getValue(), iter.getValue()));
    		}	
    	}
    	
    	// Adds regions to regionsList
    	regionsList = getSelectOptionsList(picklistRegionsSchema.getPicklistValues());

		// Adds departments to departmentsList
		departmentsList = getSelectOptionsList(picklistDepartmentSchema.getPicklistValues());
		
    	// Adds plan budget codes to planBudgetCodesList
    	planBudgetCodesList = getSelectOptionsList(picklistPlanBudgetCodesSchema.getPicklistValues());
    	
    	// Adds plan budget codes to planBudgetCodesList
    	pbBudgetOwnersList = getSelectOptionsList(picklistPbBudgetOwnersSchema.getPicklistValues());
		

    	// Adds the values True and False to recurringList
    	recurringList.add(new SelectOption('true','True'));
    	recurringList.add(new SelectOption('false','False'));
    }
	
    /*
     * Method: getSelectOptionsList()
     * Return a list of selectOptions from a picklist values list
	 * GUS-Id : 799608
	 * Created by: Santiago Doval 7/21/10
	 * Pending review: Pablo Vigil, Guillermo Freire, Diego Febles, Angelica Buffa 
     */
	private List<SelectOption> getSelectOptionsList(List<Schema.Picklistentry> l) {
		List<SelectOption> selectOptionList = new List<SelectOption>();
    	selectOptionList.add(new SelectOption('','-None-'));
    	for (Schema.Picklistentry iter : l) {
    		selectOptionList.add(new SelectOption(iter.getValue(), iter.getValue()));
    	}
		return selectOptionList;
	}
	 
	/*
	 * Method: initializeVariables()
	 * Initialize variables. 
	 */
	private void initializeVariables() {
		errorMsg = '';
		currentPeriod = periodsList.size() > 0 ? periodsList.get(0).getValue() : '';
		currentBudgetArea = new List<String>();
		budgetId = ApexPages.currentPage() != null ? ApexPages.currentPage().getParameters().get('bid') : null; 
		budgetLevel = ApexPages.currentPage() != null ? ApexPages.currentPage().getParameters().get('level') : null;
		
		readOnly = budgetId == null && budgetLevel == null;
		for (SelectOption so : budgetAreaList) {
			currentBudgetArea.add(so.getValue());
		}

		isUserAllowed = isUserAllowedToEdit();				
	}
	
	/*
	 * Method: isUserAllowedToEdit()
	 * Checks if the user is allowed to edit
	 */
	private Boolean isUserAllowedToEdit() { 
		Boolean isAllowedToEdit = false;
		isAllowedtoEdit = Budgets__c.sObjectType.getDescribe().isUpdateable();
		
		return isAllowedToEdit; 
	} 
	
	/*
	 * Method: createTree
	 * Creates the Tree 
	 */
	private void createTree(String filterBy) {
		
		budgetNodesMap = new Map<Integer, BudgetNode>();
		
		Map<Id, BudgetNode> programBudgetsMap = new Map<Id, BudgetNode>();
		tree = new BudgetNode(i++);
		
		Id programBRTId = Schema.SObjectType.Program_Budget__c.getRecordTypeInfosByName().get('Program Spend').getRecordTypeId();
		
		String query = 'select Id, Name, Budget_Amount__c, Rollup_of_Program_Budget_Amount__c, Budget_Area__c, Period__r.Name, (Select Id, Name, Budget_Owner__c, Rollup_of_Budget_Lines__c, Program_Budget_Amount__c, Proposed_Budget__c from Program_Budgets__r where RecordTypeId = \''+programBRTId+'\' order by Name) from Budgets__c ' + filterBy + ' order by Period__r.Name,Name limit 10';
		List<Budgets__c> budgetOwners = Database.query(query);
		
		for (Budgets__c bl1 : budgetOwners) {
			BudgetNode BL1Node = new Budgets(i++, bl1);
			tree.add(BL1Node);
			addToMap(BL1Node.Id, BL1Node);
			if(bl1.id == budgetId){
				BL1Node.collapsed = false;
			}
			for (Program_Budget__c bl3 : bl1.Program_Budgets__r) {
				BudgetNode BL3Node = new ProgramBudget(i++, bl3);
				BL1Node.add(BL3Node);
				addToMap(BL3Node.Id, BL3Node);
				programBudgetsMap.put(bl3.Id, Bl3Node);
				if(bl3.id == budgetId){
					BL3Node.collapsed = false;
					BL3Node.parent.collapsed = false;
				}
			}			
		}
		
		Id programRTId = Schema.SObjectType.Budget_Line__c.getRecordTypeInfosByName().get('Program Spend').getRecordTypeId();
		
		Map<Id,BudgetNode> BLsMap = new Map<Id,BudgetNode>();
		for (Budget_Line__c bl4 : [select Id, 
										  Name, 
										  Program_Budget__c,
										  Budget_Line_Amount__c,
										  Rollup_of_Purchase_Request_Amount__c,
										  Uncommitted_Approved_Budget__c
								   from Budget_Line__c where Program_Budget__c in : programBudgetsMap.keySet() and RecordTypeId = :programRTId order by Name]) {
								   	
			BudgetNode auxBL3 = programBudgetsMap.get(bl4.Program_Budget__c);
			BudgetNode BL4Node = new BudgetLine(i++, bl4);
			auxBL3.add(BL4Node);
			addToMap(BL4Node.Id, BL4Node);
			BLsMap.put(bl4.id,BL4Node);
			if(bl4.id == budgetId){
				BL4Node.collapsed = false;
				BL4Node.parent.collapsed = false;
				BL4Node.parent.parent.collapsed = false;
			}
		}
		
		for(Purchase_Request__c pr: [select Id, 
										    Name,
										    Budget_Line_Unrequested_Amount__c, 
										    Budget_Line__c,
										    Purchase_Request_Amount__c  
									 from Purchase_Request__c where Budget_Line__c in :BLsMap.keySet() order by Name]){
			
			BudgetNode auxBL4 = BLsMap.get(pr.Budget_Line__c);
			BudgetNode BExpNode = new PurchaseRequest(i++, pr);
			auxBL4.add(BExpNode);
			addToMap(BExpNode.Id, BExpNode);
			if(pr.id == budgetId){
				BExpNode.collapsed = false;
				BExpNode.parent.collapsed = false;
				BExpNode.parent.parent.collapsed = false;
				BExpNode.parent.parent.parent.collapsed = false;				
			}		
		}
	}

	/*
	 * Method: resetCurrentPeriodAndArea()
	 * When we get to the page through the 'Manage Budgets' button then we only need to display the Period__r.Name and Budget_Area__c of the Budgets__c
	 * since only have one Budgets__c
	 */
	private void resetCurrentPeriodAndArea() {
		// I only have one Budget Owner in the tree
		if (tree.children.size() > 0) {
			periodsList.clear();
			Budgets__c bObj = ((Budgets)tree.children.get(0)).obj;
			String periodName = bObj.Period__r.Name;
			String budgetArea = bObj.Budget_Area__c;
			
			if (periodName != null && periodName != '') {
				periodsList.add(new SelectOption(periodName, periodName));			
			} else {
				errorMsg = 'Period has not been selected for this Budget.\n'; 
			}
			
			if (budgetArea != null && budgetArea != '') {
				budgetAreaList.clear();
				budgetAreaList.add(new SelectOption(budgetArea, budgetArea));			
			} else {
				errorMsg += 'Budget Area has not been selected for this Budget.\n';
			}
			
			if (errorMsg != '') errorMsg += 'Click <a href=' + DOMAIN_HOST + bObj.Id + '/e?retURL=/' + bObj.Id + '>here</a> to update the data.';	
		} else {
			currentPeriod = '';
			currentBudgetArea.clear();
		}
	}
			
	/*
	 * Method: getParentId
	 * @param childId the Id of the Program_Budget__c or Budget_Line__c 
	 * @param budgetLevel determines the level of the Budget, 'programBudget' or 'budgetLine'
	 * @return parentId the Id of the first level (Budgets__c)
	 */
	private String getParentId(String childId, String budgetLevel) {
		String parentId = '';
		if (budgetLevel == PROGRAM_BUDGET) {
			List<Program_Budget__c> l = new List<Program_Budget__c>([select Budget_Owner__c, Rollup_of_Budget_Lines__c from Program_Budget__c where Id =: childId]);
			if (l.size() > 0) {
				parentId = l.get(0).Budget_Owner__c;
			} else {
				errorMsg = 'There is no Program Budget with Id: ' + budgetId;
			}	
		} else if (budgetLevel == BUDGET_LINE) {
			List<Budget_Line__c> l = new List<Budget_Line__c>([select Program_Budget__r.Budget_Owner__c from Budget_Line__c where Id =: childId]);
			if (l.size() > 0) {
				parentId = l.get(0).Program_Budget__r.Budget_Owner__c;
			} else {
				errorMsg = 'There is no Budget Line with Id: ' + budgetId;
			}	
		} else if (budgetLevel == PURCHASE_REQUEST) {
			List<Purchase_Request__c> l = new List<Purchase_Request__c>([select Budget_Line__r.Program_Budget__r.Budget_Owner__c from Purchase_Request__c where Id =: childId]);
			if (l.size() > 0) {
				parentId = l.get(0).Budget_Line__r.Program_Budget__r.Budget_Owner__c;
			} else {
				errorMsg = 'There is no Purchase Request with Id: ' + budgetId;
			}			
		}
		return parentId;
	}	
	/*
	 * Method: addToMap();
	 * Stores all the nodes in a Map
	 */ 
	private void addToMap(Integer id, BudgetNode bn) {
		budgetNodesMap.put(id, bn);
	}
}