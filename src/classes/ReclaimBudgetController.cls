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

/*
* $Revision: #1 $
*/
public with sharing class ReclaimBudgetController {
	public String id {get;set;}
	public String level {get;set;}
	public String remaining {get;set;}
	public String amount {get;set;}	
	public String reason {get;set;}
	public String errorMsg {get;set;}
	public Boolean isProcessed {get;set;}
	public Boolean isUserAllowed {get;set;}
	public Boolean isCustomSetting {get;set;}
	
	public static ReclaimBudgetCS__c reclaimBudgetCS = ReclaimBudgetCS__c.getInstance();
    
    /* 
     * Constructor
     */		
	public ReclaimBudgetController() {
		// check if the user is allowed to process the reclaim
		if ((isCustomSetting = isCustomSetting()) && (isUserAllowed = isUserAllowed())) {
			id = ApexPages.currentPage().getParameters().get('id'); // id of the Budget that we are about to process
			level = ApexPages.currentPage().getParameters().get('level'); // Indicates whether it is a Budget Owner, Program Budget, or Budget Line
			remaining = ApexPages.currentPage().getParameters().get('remaining');
		}															      
	}
	
	private Boolean isUserAllowed() {
		Id currentUserId = UserInfo.getUserId();
		
		// Retrieve the Group where I have the users allowed to process reclaims
		List<Group> gList = [SELECT Id FROM Group WHERE Name =: reclaimBudgetCS.Public_Group_Allowed__c];
		if (gList.size() > 0) {
			String groupAllowed = gList.get(0).Id;
			// Check if the user (currentUserId) is a group member of (groupAllowed)
			List<GroupMember> gmList = [select Id from GroupMember where GroupId =: groupAllowed and UserOrGroupId =: currentUserId];
			// If the user is not in gmList then I throw an error and returns false
			if (gmList.size() == 0) {
				errorMsg = reclaimBudgetCS.User_Not_Allowed_To_Reclaim__c;
				return false;
			}	
		} else {
			return false;
		}
		return true;	
	}
    /* 
     * Trigger the reclaim budget process
     */		
	public void save() {
		if (id != null && id != '' && level != null && level != '') {
			if (amount != null && amount != '') {
				if (Pattern.matches('((-|\\+)?[0-9]+(\\.[0-9]+)?)+', amount)) {  
					Decimal amountToDeduct = BudgetUtil.parseDecimal(amount);
					if (amountToDeduct > 0) {
						isProcessed = BudgetReclaimUtility.processReclaimBudget(id, level, amountToDeduct, reason); // triggers the process
						if (isProcessed == false) {
							errorMsg = BudgetReclaimUtility.errorMsg; // retrieves errors if the process failed
						} else {
							isProcessed = true;
						}
					} else {
						errorMsg = reclaimBudgetCS.Error_Amount_Must_Be_Greater_Than_Zero__c;			
					}
				} else {
					errorMsg = reclaimBudgetCS.Error_Enter_A_Valid_Amount_Number__c;
				}
			} else {
				errorMsg = reclaimBudgetCS.Error_Amount_must_not_be_empty__c;
			}
		}
	}

	/*
	 * Method: isCustomSetting()
	 * Checks if the custom setting and its values are defined
	 */
	public static Boolean isCustomSetting() {
		if (reclaimBudgetCS == null || reclaimBudgetCS.FYEnd__c == null || reclaimBudgetCS.FYStart__c == null ||
			reclaimBudgetCS.Q1End__c == null || reclaimBudgetCS.Q1Start__c == null || reclaimBudgetCS.Q2End__c == null ||
			reclaimBudgetCS.Q2Start__c == null || reclaimBudgetCS.Q3End__c == null || reclaimBudgetCS.Q3Start__c == null ||
			reclaimBudgetCS.Q4End__c == null || reclaimBudgetCS.Q4Start__c == null || reclaimBudgetCS.Error_Amount_Must_Be_Greater_Than_Zero__c == null ||
			reclaimBudgetCS.Error_Amount_must_not_be_empty__c == null || reclaimBudgetCS.Error_Budget_Line_Level_2__c == null ||
			reclaimBudgetCS.Error_Budget_Line_Level_3__c == null || reclaimBudgetCS.Error_Budget_Line_Level__c == null ||
			reclaimBudgetCS.Error_Budget_Owner_Level_2__c == null || reclaimBudgetCS.Error_Budget_Owner_Level_3__c == null ||
			reclaimBudgetCS.Error_Budget_Owner_Level__c == null || reclaimBudgetCS.Error_Enter_A_Valid_Amount_Number__c == null ||
			reclaimBudgetCS.Error_Indicate_level__c == null || reclaimBudgetCS.Error_No_Contingency_Budget__c == null || 
			reclaimBudgetCS.Error_Program_Budget_Level_2__c == null || reclaimBudgetCS.Error_Program_Budget_Level_3__c == null ||
			reclaimBudgetCS.Error_Program_Budget_Level__c == null || reclaimBudgetCS.Error_Request_Can_Not_Be_Processed__c == null ||
			reclaimBudgetCS.Error_Updating__c == null || reclaimBudgetCS.ManagerNoteInUI1__c == null || reclaimBudgetCS.Public_Group_Allowed__c == null ||
			reclaimBudgetCS.User_Not_Allowed_To_Reclaim__c == null) {
			
			return false;
		}
		return true;
	}	 
	
	/*
	 * Method: loadCustomSetting()
	 * Loads the custom setting with values. For testing purposes
	 */
	private static void loadCustomSetting() {
		BudgetCustomSettingUtility.loadCustomSettingForTest();
		
		reclaimBudgetCS = ReclaimBudgetCS__c.getInstance();
	}
	
	private static void createPublicGroup() {
		Group g = new Group(Name = reclaimBudgetCS.Public_Group_Allowed__c);
		insert g;
		System.assertNotEquals(null, g.Id);
	}
	
	@future
	private static void createGroupMember(String groupAllowed) {
		insert new GroupMember(GroupId = groupAllowed, UserOrGroupId = UserInfo.getUserId());
	}
		
	static List<SObject> createData() {
		loadCustomSetting();
		createPublicGroup();	
		
		Period__c parentPeriod = new Period__c(Type__c = 'Year', Number__c = Decimal.valueOf('2050'));
		insert parentPeriod;
		System.assertNotEquals(null, parentPeriod.Id);
		Period__c p = new Period__c(parentPeriod__c = parentPeriod.Id, Type__c = 'Quarter', Number__c = Decimal.valueOf('1'));
		insert p;    
		System.assertNotEquals(null, p.Id);	
		
		// Create a CONTINGENCY BUDGET
		Budgets__c budgetContingency = new Budgets__c(Period__c = p.Id, Budget_Area__c = 'CONTINGENCY', Budget_Amount__c = BudgetUtil.parseDecimal('0'));
		insert budgetContingency;
		System.assertNotEquals(null, budgetContingency.Id);
		// Create Budgets
		Budgets__c budgetOwner = new Budgets__c(Period__c = p.Id, Budget_Area__c = 'test user', Budget_Amount__c = BudgetUtil.parseDecimal('10000'));
		insert budgetOwner;
		System.assertNotEquals(null, budgetOwner.Id);
		
		Program_Budget__c programBudget = new Program_Budget__c(Budget_Owner__c = budgetOwner.Id, Short_Name__c = 'testreclaim', Program_Budget_Amount__c = BudgetUtil.parseDecimal('5000'));
		insert programBudget;
		System.assertNotEquals(null, programBudget.Id);
		
		Budget_Line__c budgetLine = new Budget_Line__c(Program_Budget__c = programBudget.Id, Short_Name__c = 'testreclaim', Recurring__c = false, Budget_Line_Amount__c = BudgetUtil.parseDecimal('2000'));
		insert budgetLine;
		System.assertNotEquals(null, budgetLine.Id);
		
		// Retrieve contingency for that period
		Budgets__c contingency = [select Id, Budget_Amount__c from Budgets__c where Period__c =: p.Id and Budget_Area__c =: 'CONTINGENCY' limit 1];
		System.assertNotEquals(null, contingency.Id);		
		
		return new List<SObject> {p, budgetOwner, programBudget, budgetLine, contingency};	
	}

	static testMethod void testBudgetLineLevel() {
		
		List<SObject> l = createData();
		
		Period__c p = (Period__c) l.get(0);
		Budgets__c budgetOwner = (Budgets__c) l.get(1);
		Program_Budget__c programBudget = (Program_Budget__c) l.get(2);
		Budget_Line__c budgetLine = (Budget_Line__c) l.get(3);
		Budgets__c contingency = (Budgets__c) l.get(4);
		
		// Set page parameters - make the process starts from budgetLine level
		ApexPages.currentPage().getParameters().put('id', budgetLine.Id);
		ApexPages.currentPage().getParameters().put('level', 'budgetLine');
		
		// Add user to Public group
		List<Group> gList = [SELECT Id FROM Group WHERE Name =: reclaimBudgetCS.Public_Group_Allowed__c];
		if (gList.size() > 0) {
			String groupAllowed = gList.get(0).Id;
			List<GroupMember> gmList = [select Id from GroupMember where GroupId =: groupAllowed and UserOrGroupId =: UserInfo.getUserId()];
			if (gmList.size() == 0) {
				// Add user as a GroupMember
				User usr = [Select id from User where Id = :UserInfo.getUserId()];
				System.RunAs(usr) {
					Test.startTest();
					createGroupMember(groupAllowed);
					Test.stopTest();
				}
			}
		}	
		
		ReclaimBudgetController rbc = new ReclaimBudgetController();
		rbc.amount = '1000';
		rbc.reason = 'testing process from budgetLine';
		rbc.save();
		
		// Retrieve data
		Budgets__c boTest = [select Id, Budget_Amount__c from Budgets__c where Id =: budgetOwner.Id];
		System.assertNotEquals(null, boTest.Id);
		
		Program_Budget__c pbTest = [select Id, Program_Budget_Amount__c from Program_Budget__c where Id =: programBudget.Id];
		System.assertNotEquals(null, pbTest.Id);
		
		Budget_Line__c blTest = [select Id, Budget_Line_Amount__c from Budget_Line__c where Id =: budgetLine.Id];
		System.assertNotEquals(null, blTest.Id);
		
		// Budget Owner Approved_Budget__c should've been deducted by rbc.amount
		System.assertEquals(budgetOwner.Budget_Amount__c - BudgetUtil.parseDecimal(rbc.amount), boTest.Budget_Amount__c);
		
		// Program Budget Approved_Budget__c should've been deducted by rbc.amount
		System.assertEquals(programBudget.Program_Budget_Amount__c - BudgetUtil.parseDecimal(rbc.amount), pbTest.Program_Budget_Amount__c);
		
		// Budget Line Approved_Budget__c should've been deducted by rbc.amount
		System.assertEquals(budgetLine.Budget_Line_Amount__c - BudgetUtil.parseDecimal(rbc.amount), blTest.Budget_Line_Amount__c);
		
		// Test contingency
		Budgets__c contingencyTest = [select Id, Budget_Amount__c from Budgets__c where Id =: contingency.Id and Period__c =: p.Id and Budget_Area__c =: 'CONTINGENCY'];
		System.debug('#### cont ' + contingencyTest.Budget_Amount__c);
		System.assertNotEquals(null, contingencyTest.Id);
		
		// Contingency Approved_Budget__c should've been deducted by rbc.amount
		System.assertEquals(contingency.Budget_Amount__c - BudgetUtil.parseDecimal(rbc.amount), contingencyTest.Budget_Amount__c);
		
		// Test reclaim transaction
		List<Reclaimed_Transaction__c> rtl = [select Id, 
													 Budget_Id__c, 
													 Amount__c, 
													 Reason__c 
											  from Reclaimed_Transaction__c 
											  where Budget_Id__c =: budgetOwner.Id or Budget_Id__c =: programBudget.Id or Budget_Id__c =: budgetLine.Id];
											  
		System.assertNotEquals(null, rtl);
		// 3 records were updated 
		System.assertEquals(3, rtl.size());
		System.assertEquals(BudgetUtil.parseDecimal(rbc.amount), rtl.get(0).Amount__c);		
	}
	
	static testMethod void testProgramBudgetLevel() {
		List<SObject> l = createData();
		
		Period__c p = (Period__c) l.get(0);
		Budgets__c budgetOwner = (Budgets__c) l.get(1);
		Program_Budget__c programBudget = (Program_Budget__c) l.get(2);
		Budget_Line__c budgetLine = (Budget_Line__c) l.get(3);
		Budgets__c contingency = (Budgets__c) l.get(4);
		
		// Set page parameters - make the process starts from programBudget level
		ApexPages.currentPage().getParameters().put('id', programBudget.Id);
		ApexPages.currentPage().getParameters().put('level', 'programBudget');

		// Add user to Public group
		List<Group> gList = [SELECT Id FROM Group WHERE Name =: reclaimBudgetCS.Public_Group_Allowed__c];
		if (gList.size() > 0) {
			String groupAllowed = gList.get(0).Id;
			List<GroupMember> gmList = [select Id from GroupMember where GroupId =: groupAllowed and UserOrGroupId =: UserInfo.getUserId()];
			if (gmList.size() == 0) {
				// Add user as a GroupMember
				User usr = [Select id from User where Id = :UserInfo.getUserId()];
				System.RunAs(usr) {
					Test.startTest();
					createGroupMember(groupAllowed);
					Test.stopTest();
				}
			}
		}	
		
		ReclaimBudgetController rbc = new ReclaimBudgetController();
		rbc.amount = '1000';
		rbc.reason = 'testing process from programBudget';
		rbc.save();
		
		// Retrieve data
		Budgets__c boTest = [select Id, Budget_Amount__c from Budgets__c where Id =: budgetOwner.Id];
		System.assertNotEquals(null, boTest.Id);
		
		Program_Budget__c pbTest = [select Id, Program_Budget_Amount__c from Program_Budget__c where Id =: programBudget.Id];
		System.assertNotEquals(null, pbTest.Id);
		
		Budget_Line__c blTest = [select Id, Budget_Line_Amount__c from Budget_Line__c where Id =: budgetLine.Id];
		System.assertNotEquals(null, blTest.Id);
		
		// Budget Owner Approved_Budget__c should've been deducted by rbc.amount
		System.assertEquals(budgetOwner.Budget_Amount__c - BudgetUtil.parseDecimal(rbc.amount), boTest.Budget_Amount__c);
		
		// Program Budget Approved_Budget__c should've been deducted by rbc.amount
		System.assertEquals(programBudget.Program_Budget_Amount__c - BudgetUtil.parseDecimal(rbc.amount), pbTest.Program_Budget_Amount__c);
		
		// Budget Line Approved_Budget__c should've not been deducted by rbc.amount b/c the process started from programBudget level
		System.assertEquals(budgetLine.Budget_Line_Amount__c, blTest.Budget_Line_Amount__c);

		// Test contingency
		Budgets__c contingencyTest = [select Id, Budget_Amount__c from Budgets__c where Id =: contingency.Id and Period__c =: p.Id and Budget_Area__c =: 'CONTINGENCY'];
		System.assertNotEquals(null, contingencyTest.Id);

		// Contingency Approved_Budget__c should've been deducted by rbc2.amount
		System.assertEquals(contingency.Budget_Amount__c - BudgetUtil.parseDecimal(rbc.amount), contingencyTest.Budget_Amount__c);

		// Test reclaim transaction
		List<Reclaimed_Transaction__c> rtl = [select Id, 
													 Budget_Id__c, 
													 Amount__c, 
													 Reason__c 
											  from Reclaimed_Transaction__c 
											  where Budget_Id__c =: budgetOwner.Id or Budget_Id__c =: programBudget.Id or Budget_Id__c =: budgetLine.Id];									  
		System.assertNotEquals(null, rtl);
		// 2 records were updated 
		System.assertEquals(2, rtl.size());
		System.assertEquals(BudgetUtil.parseDecimal(rbc.amount), rtl.get(0).Amount__c);	
	}
	
	static testMethod void testBudgetLevel() {
		List<SObject> l = createData();
		
		Period__c p = (Period__c) l.get(0);
		Budgets__c budgetOwner = (Budgets__c) l.get(1);
		Program_Budget__c programBudget = (Program_Budget__c) l.get(2);
		Budget_Line__c budgetLine = (Budget_Line__c) l.get(3);
		Budgets__c contingency = (Budgets__c) l.get(4);

		// Set page parameters - make the process starts from budgetOwner level
		ApexPages.currentPage().getParameters().put('id', budgetOwner.Id);
		ApexPages.currentPage().getParameters().put('level', 'budgetOwner');

		// Add user to Public group
		List<Group> gList = [SELECT Id FROM Group WHERE Name =: reclaimBudgetCS.Public_Group_Allowed__c];
		if (gList.size() > 0) {
			String groupAllowed = gList.get(0).Id;
			List<GroupMember> gmList = [select Id from GroupMember where GroupId =: groupAllowed and UserOrGroupId =: UserInfo.getUserId()];
			if (gmList.size() == 0) {
				// Add user as a GroupMember
				User usr = [Select id from User where Id = :UserInfo.getUserId()];
				System.RunAs(usr) {
					Test.startTest();
					createGroupMember(groupAllowed);
					Test.stopTest();
				}
			}
		}	
		
		ReclaimBudgetController rbc = new ReclaimBudgetController();
		rbc.amount = '1000';
		rbc.reason = 'testing process from budgetOwner';
		rbc.save();
		
		// Retrieve data
		Budgets__c boTest = [select Id, Budget_Amount__c from Budgets__c where Id =: budgetOwner.Id];
		System.assertNotEquals(null, boTest.Id);
		
		Program_Budget__c pbTest = [select Id, Program_Budget_Amount__c from Program_Budget__c where Id =: programBudget.Id];
		System.assertNotEquals(null, pbTest.Id);
		
		Budget_Line__c blTest = [select Id, Budget_Line_Amount__c from Budget_Line__c where Id =: budgetLine.Id];
		System.assertNotEquals(null, blTest.Id);
		
		// Budget Owner Approved_Budget__c should've been deducted by rbc.amount
		System.assertEquals(budgetOwner.Budget_Amount__c - BudgetUtil.parseDecimal(rbc.amount), boTest.Budget_Amount__c);
		
		// Program Budget Approved_Budget__c should've not been deducted by rbc.amount b/c the process started from budgetOwner level
		System.assertEquals(programBudget.Program_Budget_Amount__c, pbTest.Program_Budget_Amount__c);
		
		// Budget Line Approved_Budget__c should've not been deducted by rbc.amount b/c the process started from budgetOwner level
		System.assertEquals(budgetLine.Budget_Line_Amount__c, blTest.Budget_Line_Amount__c);

		// Test contingency
		Budgets__c contingencyTest = [select Id, Budget_Amount__c from Budgets__c where Id =: contingency.Id and Period__c =: p.Id and Budget_Area__c =: 'CONTINGENCY'];
		System.assertNotEquals(null, contingencyTest.Id);

		// Contingency Approved_Budget__c should've been deducted by rbc.amount
		System.assertEquals(contingency.Budget_Amount__c - BudgetUtil.parseDecimal(rbc.amount), contingencyTest.Budget_Amount__c);

		// Test reclaim transaction
		List<Reclaimed_Transaction__c> rtl = [select Id, 
													 Budget_Id__c, 
													 Amount__c, 
													 Reason__c 
											  from Reclaimed_Transaction__c 
											  where Budget_Id__c =: budgetOwner.Id or Budget_Id__c =: programBudget.Id or Budget_Id__c =: budgetLine.Id];
											  
		System.assertNotEquals(null, rtl);
		// 1 record was updated 
		System.assertEquals(1, rtl.size());
		System.assertEquals(BudgetUtil.parseDecimal(rbc.amount), rtl.get(0).Amount__c);	
	}
		
	static testMethod void testErrorsAtBudgetsLevel() {

		List<SObject> l = createData();
		
		Budgets__c budgetOwner = (Budgets__c) l.get(1);

		// Set page parameters - make the process starts from budgetOwner level
		ApexPages.currentPage().getParameters().put('id', budgetOwner.Id);
		ApexPages.currentPage().getParameters().put('level', 'budgetOwner');

		// Add user to Public group
		List<Group> gList = [SELECT Id FROM Group WHERE Name =: reclaimBudgetCS.Public_Group_Allowed__c];
		if (gList.size() > 0) {
			String groupAllowed = gList.get(0).Id;
			List<GroupMember> gmList = [select Id from GroupMember where GroupId =: groupAllowed and UserOrGroupId =: UserInfo.getUserId()];
			if (gmList.size() == 0) {
				// Add user as a GroupMember
				User usr = [Select id from User where Id = :UserInfo.getUserId()];
				System.RunAs(usr) {
					Test.startTest();
					createGroupMember(groupAllowed);
					Test.stopTest();
				}
			}
		}	
		
		ReclaimBudgetController rbc = new ReclaimBudgetController();
		// test error when amount = 0
		rbc.amount = '0';
		rbc.reason = 'testing errors';
		rbc.save();
		
		System.assertEquals(rbc.errorMsg, ReclaimBudgetController.reclaimBudgetCS.Error_Amount_Must_Be_Greater_Than_Zero__c);
		
		// test error when amount is greater than Budgets__c.Unallocated_Program_Budget_Amount__c
		rbc.amount = '11000';
		rbc.reason = 'testing errors';
		rbc.save();
		
		System.assertEquals(rbc.errorMsg, ReclaimBudgetController.reclaimBudgetCS.Error_Budget_Owner_Level__c);

		// test error when unallocated = 0
		budgetOwner.Budget_Amount__c = 0;
		update budgetOwner;
		
		rbc.amount = '1000';
		rbc.reason = 'testing errors';
		rbc.save();
		
		System.assertEquals(rbc.errorMsg, ReclaimBudgetController.reclaimBudgetCS.Error_Budget_Owner_Level_2__c);					
	}	

	static testMethod void testErrorsAtProgramBudgetLevel() {

		List<SObject> l = createData();
		
		Program_Budget__c programBudget = (Program_Budget__c) l.get(2);

		// Set page parameters - make the process starts from budgetOwner level
		ApexPages.currentPage().getParameters().put('id', programBudget.Id);
		ApexPages.currentPage().getParameters().put('level', 'programBudget');

		// Add user to Public group
		List<Group> gList = [SELECT Id FROM Group WHERE Name =: reclaimBudgetCS.Public_Group_Allowed__c];
		if (gList.size() > 0) {
			String groupAllowed = gList.get(0).Id;
			List<GroupMember> gmList = [select Id from GroupMember where GroupId =: groupAllowed and UserOrGroupId =: UserInfo.getUserId()];
			if (gmList.size() == 0) {
				// Add user as a GroupMember
				User usr = [Select id from User where Id = :UserInfo.getUserId()];
				System.RunAs(usr) {
					Test.startTest();
					createGroupMember(groupAllowed);
					Test.stopTest();
				}
			}
		}	
		
		ReclaimBudgetController rbc = new ReclaimBudgetController();
		// test error when amount = 0
		rbc.amount = '0';
		rbc.reason = 'testing errors';
		rbc.save();
		
		System.assertEquals(rbc.errorMsg, ReclaimBudgetController.reclaimBudgetCS.Error_Amount_Must_Be_Greater_Than_Zero__c);
		
		// test error when amount is greater than Program_Budget__c.Unallocated_Budget_Line_Amount__c
		rbc.amount = '6000';
		rbc.reason = 'testing errors';
		rbc.save();
		
		System.assertEquals(rbc.errorMsg, ReclaimBudgetController.reclaimBudgetCS.Error_Program_Budget_Level__c);

		// test error when unallocated = 0
		// In order to reduce the Program_Budget_Amount__c I need to reduce the Budget_Line amount
		List<Budget_Line__c> blsList = [select Id, Budget_Line_Amount__c from Budget_Line__c where Program_Budget__c =: programBudget.Id];
		for (Budget_Line__c bl : blsList) {
			bl.Budget_Line_Amount__c = 0;
		}
		update blsList;
		programBudget.Program_Budget_Amount__c = 0;
		update programBudget;
		
		rbc.amount = '1000';
		rbc.reason = 'testing errors';
		rbc.save();
		
		System.assertEquals(rbc.errorMsg, ReclaimBudgetController.reclaimBudgetCS.Error_Program_Budget_Level_2__c);	
	}	

	static testMethod void testErrorsAtBudgetLineLevel() {

		List<SObject> l = createData();
		
		Budget_Line__c budgetLine = (Budget_Line__c) l.get(3);

		// Set page parameters - make the process starts from budgetOwner level
		ApexPages.currentPage().getParameters().put('id', budgetLine.Id);
		ApexPages.currentPage().getParameters().put('level', 'budgetLine');
		
		// Add user to Public group
		List<Group> gList = [SELECT Id FROM Group WHERE Name =: reclaimBudgetCS.Public_Group_Allowed__c];
		if (gList.size() > 0) {
			String groupAllowed = gList.get(0).Id;
			List<GroupMember> gmList = [select Id from GroupMember where GroupId =: groupAllowed and UserOrGroupId =: UserInfo.getUserId()];
			if (gmList.size() == 0) {
				// Add user as a GroupMember
				User usr = [Select id from User where Id = :UserInfo.getUserId()];
				System.RunAs(usr) {
					Test.startTest();
					createGroupMember(groupAllowed);
					Test.stopTest();
				}
			}
		}	

		ReclaimBudgetController rbc = new ReclaimBudgetController();
		// test error when amount = 0
		rbc.amount = '0';
		rbc.reason = 'testing errors';
		rbc.save();
		
		System.assertEquals(rbc.errorMsg, ReclaimBudgetController.reclaimBudgetCS.Error_Amount_Must_Be_Greater_Than_Zero__c);
		
		// test error when amount is greater than Budget_Line__c.Uncommitted_Approved_Budget__c
		rbc.amount = '3000';
		rbc.reason = 'testing errors';
		rbc.save();
		
		System.assertEquals(rbc.errorMsg, ReclaimBudgetController.reclaimBudgetCS.Error_Budget_Line_Level__c);
		
		// test error when uncommitted = 0
		budgetLine.Budget_Line_Amount__c = 0;
		update budgetLine;
		
		rbc.amount = '1000';
		rbc.reason = 'testing errors';
		rbc.save();
		
		System.assertEquals(rbc.errorMsg, ReclaimBudgetController.reclaimBudgetCS.Error_Budget_Line_Level_2__c);	
	}
	
    static testMethod void testReclaimBudgetCSsetting() {
    	
    	if (ReclaimBudgetController.reclaimBudgetCS != null) {
    		System.debug('### Found settings - deleting them...');
    		delete [select Id from ReclaimBudgetCS__c];
    		// Check if the setting is null
    		ReclaimBudgetController.reclaimBudgetCS = ReclaimBudgetCS__c.getInstance();
    		System.assertEquals(false, ReclaimBudgetController.isCustomSetting());
    	} else {
    		System.debug('### No settings, okay');
    	}
    }			     		
}