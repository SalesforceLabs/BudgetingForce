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

/* This class provides the framework for implementing Recurring budgets.
 * The basic flow is: 
 *    (a) logic to process recurring budget
 *
 * @since 2010-06
 */
public class BudgetRecurringUtility {
	
    public static String errorMsg {get;set;}
    public static Boolean isTest {get;set;} // for testing purposes
    
    static {
    	isTest = false;
    }
    
    /*
     * Method: processRecurringBudget
     * Method called by BudgetLineTrigger on AfterInsert, AfterUpdate
     * When we insert or update a Budget Line (Budget_Line__c), if Recurring is true, then It copies the tree
     * to the periods that are calculated from Recurring_Start_Period__c and Number_of_Quarters
     */
    public static void processRecurringBudget(List<Budget_Line__c> budgetLines, List<Budget_Line__c> oldBudgetLines) {
		Map<Id, Budget_Line__c> oldBudgetLinesById = new Map<Id, Budget_Line__c>();
		if (oldBudgetLines != null)
		{
			for (Budget_Line__c oldBudget : oldBudgetLines)
			{
				oldBudgetLinesById.put(oldBudget.Id, oldBudget);
			}
		}
		
		for ( Budget_Line__c budgetLine : budgetLines)
		{
			if ((budgetLine.Recurring__c == true && oldBudgetLines == null) || (budgetLine.Recurring__c == true && oldBudgetLinesById.get(budgetLine.Id).Recurring__c == false)){
				
			
	 		if(budgetLine.Recurring_Start_Period__c == null || budgetLine.Number_of_Quarters__c == null || budgetLine.Number_of_Quarters__c < 2){return;}
	 	
	 		Integer j = 1; 		
	 		BudgetNode recurringTree = new BudgetNode(j++);  
	    	BudgetPeriodUtility bpu = new BudgetPeriodUtility();
	    	Map<String, Budgets__c> bOwnersMap = new Map<String, Budgets__c>();
	    	Map<String, List<Budget_Line__c>> bLineMap = new Map<String, List<Budget_Line__c>>();
	    	List<Program_Budget__c> pbList = new List<Program_Budget__c>();
	    	
	    	
	    	Period__c recurringStartPeriod = [select Id, Name, Start_Date__c, End_Date__c, Type__c, Number__c, ParentPeriod__c, ParentPeriod__r.Id, ParentPeriod__r.Name, ParentPeriod__r.Start_Date__c, ParentPeriod__r.End_Date__c, ParentPeriod__r.Type__c, ParentPeriod__r.Number__c from Period__c where Id =: budgetLine.Recurring_Start_Period__c limit 1][0];
	  		Program_Budget__c budgetParent = [select Id, 
	  												 Name,
	  												 Short_Name__c, 
	  												 Program_Type__c, 
	  												 Region__c, 
	  												 RecordTypeId,
	  												 Budget_Area__c,
	  												 Budget_Owner__r.Id, 
	  												 Budget_Owner__r.Name, 
	  												 Budget_Owner__r.RecordTypeId,
	  												 Budget_Owner__r.Budget_Area__c,
	  												 Rollup_of_Budget_Lines__c
	  										 from Program_Budget__c where Id =: budgetLine.Program_Budget__c limit 1];   	
	    	
	    	List<Period__c> recurringPeriods = bpu.getRecurringPeriods(recurringStartPeriod,Math.round(budgetLine.Number_of_Quarters__c));
	    	
	    	// We retrieve the Budget Owners to store them in a Map
	    	for (Budgets__c bo : [select Id, Name, Budget_Amount__c, Rollup_of_Program_Budget_Amount__c, (Select Id, Name, Rollup_of_Budget_Lines__c, Program_Budget_Amount__c, Budget_Owner__c from Program_Budgets__r) from Budgets__c where Period__c in : recurringPeriods]) {
	    		if(!bOwnersMap.containsKey(bo.Name)) bOwnersMap.put(bo.Name, bo);
	    		if (bo.Program_Budgets__r.size() > 0) pbList.addAll(bo.Program_Budgets__r); 
	    	}
	    	
	    	// We retrieve the Budget Lines to store them in a Map 
			for (Budget_Line__c bl : [select Id, Name, Budget_Line_Amount__c, Program_Budget__c from Budget_Line__c where Program_Budget__c in : pbList]) {
				if (bLineMap.containsKey(bl.Program_Budget__c)) {
					bLineMap.get(bl.Program_Budget__c).add(bl);
				} else {
					bLineMap.put(bl.Program_Budget__c, new List<Budget_Line__c>{bl});
				}
			}     	
	    	// returns a list of all the periods for which we are going to copy the tree 
			// Iterate over the periods - We will check if the tree on which the new Budget Line belongs to, exists for other periods
	    	for (Period__c p : recurringPeriods) {
				// Items to copy
				Program_Budget__c bl3 = new Program_Budget__c(Short_Name__c = budgetParent.Short_Name__c, 
															  Program_Type__c = budgetParent.Program_Type__c,
															  Budget_Area__c = budgetParent.Budget_Area__c, 
															  Region__c = budgetParent.Region__c, 
															  RecordTypeId = budgetParent.RecordTypeId,
															  Program_Budget_Amount__c = 0);
	
							
				Budget_Line__c bl4 = new Budget_Line__c(Short_Name__c = budgetLine.Short_Name__c,
														Annual_Budget__c = false,
														Recurring__c = false,	 
														Region__c = budgetLine.Region__c, 
														RecordTypeId = budgetLine.RecordTypeId,
														Description__c = budgetLine.Description__c,
														Budget_Line_Amount__c = 0);
														
	    		
	    		// We generate the Name to see if it exists in the map that have all the Budget Owners
	    		// Since the Budget Owner Name generates automatically on insertion, we need to form it as it is
	    		String auxBOwnerName = budgetParent.Budget_Owner__r.Name;
				String bOwnerName = auxBOwnerName.replace(auxBOwnerName.substring(0,6), p.Name);
				// If it is in the Map, means that there is a Budget Owner with the same name but for a diferent period, 
				// so we go further and check if the Program Budget also exists.    					    		
	    		if (bOwnersMap.containsKey(bOwnerName))	{
	    			Budgets__c b = bOwnersMap.get(bOwnerName);
	    			BudgetNode BL1Node = new Budgets(j++, b);
	    			recurringTree.add(BL1Node); // add node to recurringTree
	    			BudgetNode BL3Node = null;
	    			// We iterate over the Program Budgets that are related to the Budget Owner
	    			for (Program_Budget__c pb : b.Program_Budgets__r) {
	    				BudgetNode BL4Node = null;
	   					// We generate the Program Budget Name 
	    				String auxPBudgetName = budgetParent.Name;
	    				String pBudgetName = auxPBudgetName.replace(auxPBudgetName.substring(0,6), p.Name);
	    				// Check if a Program Budget exist for this period, if it does then we don't add it as a new Program Budget
	    				if (pb.Name == pBudgetName) {
	    					BL3Node = new ProgramBudget(j++, pb);
	    					BL1Node.add(BL3Node);
	    					// Check if there are Budget Lines for current Program Budget
	    					if (bLineMap.containsKey(pb.Id)) {
	    						List<Budget_Line__c> auxBlList = bLineMap.get(pb.Id);
	    						// We iterate over the Budget Lines that are related to the Program Budget
	    						for (Budget_Line__c bl : auxBlList) {
	    							// Generate Budget Line name
	    							String auxBlName = budgetLine.Name;
	    							String blName = auxBlName.replace(auxBlName.substring(0,6), p.Name);
	    							// Check if a Budget Line exists for this period, if it does then we don't add it as a new Budget Line
	    							if (bl.Name == blName) {
			    						BL4Node = new BudgetLine(j++, bl);
	    								BL3Node.add(BL4Node);
	    								break;					
	    							}
	    						}
	    					}
	    					// If BL4Node is null means that we have to add a new budget line for the period I am iterating over
							if (BL4Node == null) {
								BL4Node = new BudgetLine(j++, bl4);
								BL3Node.add(BL4Node);
							}      										
	    				}
	    			} 
	    			// If BL3Node is null means that we have to add a new Program Budget and a Budget Line for the period I am iteration over.
	    			if (BL3Node == null) {
	    				BL3Node = new ProgramBudget(j++, bl3);
	    				BL1Node.add(BL3Node);
						BudgetNode BL4Node = new BudgetLine(j++, bl4);
						BL3Node.add(BL4Node);    				
	    			}     			   			
	    		} else {
	    			System.debug('>>> New hierarchy');
					Budgets__c bl1 = new Budgets__c(Period__c = p.Id, 
													Budget_Area__c = budgetParent.Budget_Owner__r.Budget_Area__c, 
												    RecordTypeId = budgetParent.Budget_Owner__r.RecordTypeId,
												    Budget_Amount__c = 0);
	    			
	    			// If I am in a test then I create the name manually, just in case that the wf rule is inactive
	    			if (isTest) {
	    				bl1.Name = p.Name + ' ' + bl1.Budget_Area__c;
	    			}
	    				
	    			BudgetNode BL1Node = new Budgets(j++, bl1);
	    			recurringTree.add(BL1Node);
	    			
	    			BudgetNode BL3Node = new ProgramBudget(j++, bl3);
	    			BL1Node.add(BL3Node);
	    			
	    			BudgetNode BL4Node = new BudgetLine(j++, bl4);
	    			BL3Node.add(BL4Node);   			
	    		}
	    	}
	    	save(recurringTree); // save recurringTree
			}
		}
    }

    /*
     * Method: save()
     * Saves the tree to the database
     */    
    private static void save(BudgetNode tree) {
		errorMsg = BudgetUtil.save(tree);    
    }
}