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

/* This class provides the framework for implementing reclaim budget.
 * The basic flow is: 
 *    (a) logic to process reclaim budget
 *    (b) Use allocateToContingency to allocate amount into the Contingency budget
 *    (b) Use saveReclaimBudget method to update Budget Owner, Program Budget, and Budget Line
 *    (c) Use recordTransaction to record the action in a custom object
 *
 * @since 2010-05
 */
public class BudgetReclaimUtility {
	
	public static String errorMsg {get;set;}
	
	private static Savepoint sp;
	
	private static Budgets__c budgetOwner {get;set;}
	private static Program_Budget__c programBudget {get;set;}
	private static Budget_Line__c budgetLine {get;set;}
	private static List<BudgetGeneric> budgetsToRecord = new List<BudgetGeneric>(); 
	private static Id periodOfContingency {get;set;}
	
	private static ReclaimBudgetCS__c reclaimBudgetCS = ReclaimBudgetCS__c.getInstance(); 
	
    private static final String BUDGET_OWNER = 'budgetOwner';
    private static final String PROGRAM_BUDGET = 'programBudget';
    private static final String BUDGET_LINE = 'budgetLine';
    private static final String CONTINGENCY = 'CONTINGENCY';
    
    /* Process the reclaim budget starting at the level indicated in @param level
     *
     * @param id the id of the Budget that needs to be processed
     * @param level indicates if it is a Budget Owner, Program Budget, or Budget Line
     * @param amount the amount to deduct
     * @param reason the reason why a deduction needs to be performed
     * @return a Boolean indicating whether the process was successful or not 
     */
	public static Boolean processReclaimBudget(String id, String level, Decimal amountToDeduct, String reason) {
		//Decimal amountToDeduct = BudgetUtil.parseDecimal(amount);
		errorMsg = '';
		if (level == BUDGET_LINE) {
			processBudgetLineLevel(id, amountToDeduct);
		} else if (level == PROGRAM_BUDGET) {
			processProgramBudgetLevel(id, amountToDeduct, true);
		} else if (level == BUDGET_OWNER) {
			processBudgetOwnerLevel(id, amountToDeduct, true);
		} else {
			errorMsg = reclaimBudgetCS.Error_Indicate_level__c;
		}
		if (errorMsg != '') return false;
		
		allocateToContingency(amountToDeduct); // allocate amountToDeduct in a Contingency Budget 
		
		if (errorMsg != '') return false;
		
		saveReclaimBudget(); // save the Budgets that were processed
		
		if (errorMsg != '') return false;
		
		recordTransaction(amountToDeduct, reason); // record the transaction in Reclaimed_Transactions__c
		
		return true;
	}
	
    /* Process the Budget Line
     *
     * @param id the id of the Budget Line that needs to be processed
     * @param amountToDeduct the amount that needs to be deducted from Approved_Amount__c
     */	
	private static void processBudgetLineLevel(String id, Decimal amountToDeduct) {
		List<Budget_Line__c> l = new List<Budget_Line__c>([select Id, 
																  Name,	
																  Budget_Line_Amount__c, 
																  Uncommitted_Approved_Budget__c, 
																  Program_Budget__r.Id from Budget_Line__c where Id =: id]); 
		if(l.size() > 0) {
			Budget_Line__c bl4 = l.get(0);
			if (bl4.Uncommitted_Approved_Budget__c > 0) {
				if (bl4.Uncommitted_Approved_Budget__c >= amountToDeduct) {
					bl4.Budget_Line_Amount__c -= amountToDeduct;
					budgetLine = bl4; // we keep it so we can reference it later to update 
					budgetsToRecord.add(new BudgetGeneric(bl4.Id, bl4.Name, 'Budget Line'));
					processProgramBudgetLevel(bl4.Program_Budget__r.Id, amountToDeduct, false); // process the parent
				} else {
					errorMsg = reclaimBudgetCS.Error_Budget_Line_Level__c;
				}
			} else {
				errorMsg = reclaimBudgetCS.Error_Budget_Line_Level_2__c;
			}			
		} else {
			errorMsg = reclaimBudgetCS.Error_Budget_Line_Level_3__c;		
		}
	}

    /* Process the Program Budget
     *
     * @param id the id of the Program Budget that needs to be processed
     * @param amountToDeduct the amount that needs to be deducted from Approved_Budget__c
     * @param initializer determines if this method initializes the Reclaim process or not
     */		
	private static void processProgramBudgetLevel(String id, Decimal amountToDeduct, Boolean initializer) {
		List<Program_Budget__c> l = new List<Program_Budget__c>([select Id, 
																		Name,
																		Program_Budget_Amount__c, 
																		Unallocated_Budget_Line_Amount__c, 
																		Budget_Owner__r.Id from Program_Budget__c where Id =: id]);
		if (l.size() > 0) {
			Program_Budget__c bl3 = l.get(0);			
			if (bl3.Unallocated_Budget_Line_Amount__c > 0 || !initializer) {
				if (bl3.Unallocated_Budget_Line_Amount__c >= amountToDeduct || !initializer) {
					bl3.Program_Budget_Amount__c -= amountToDeduct;
					programBudget = bl3; // we keep it so we can reference it later to update
					budgetsToRecord.add(new BudgetGeneric(bl3.Id, bl3.Name, 'Program Budget'));
					processBudgetOwnerLevel(bl3.Budget_Owner__r.Id, amountToDeduct, false);
				} else {
					errorMsg = reclaimBudgetCS.Error_Program_Budget_Level__c;
				}
			} else {
				errorMsg = reclaimBudgetCS.Error_Program_Budget_Level_2__c;
			}			
		} else {
			errorMsg = reclaimBudgetCS.Error_Program_Budget_Level_3__c;		
		}
	}
	
    /* Process the Budget Owner
     *
     * @param id the id of the Budget Owner that needs to be processed
     * @param amountToDeduct the amount that needs to be deducted from Approved_Budget__c
     * @param initializer determines if this method initializes the Reclaim process or not
     */		
	private static void processBudgetOwnerLevel(String id, Decimal amountToDeduct, Boolean initializer) {
		List<Budgets__c> l = new List<Budgets__c>([select Id,
														  Name, 
														  OwnerId, 
														  Budget_Amount__c, 
														  Unallocated_Program_Budget_Amount__c, 
														  Period__c from Budgets__c where Id =: id]);
		if (l.size() > 0) {
			Budgets__c bl1 = l.get(0);			
			if (bl1.Unallocated_Program_Budget_Amount__c > 0 || !initializer) {
				if (bl1.Unallocated_Program_Budget_Amount__c >= amountToDeduct || !initializer) {
					bl1.Budget_Amount__c -= amountToDeduct;
					budgetOwner = bl1; // we keep it so we can reference it later to update
					budgetsToRecord.add(new BudgetGeneric(bl1.Id, bl1.Name, 'Budget'));
					periodOfContingency = bl1.Period__c; // We'll use this value to query for the Contingency budget.					
				} else {
					errorMsg = reclaimBudgetCS.Error_Budget_Owner_Level__c;
				}
			} else {
				errorMsg = reclaimBudgetCS.Error_Budget_Owner_Level_2__c;
			}			
		} else {
			errorMsg = reclaimBudgetCS.Error_Budget_Owner_Level_3__c;
		}
	}

    /* Allocate the amountToDeduct in the Contingency budget for the period to which the Budget Owner belongs to.
     *
     * @param amountToDeduct the amount that needs to be deducted from Approved_Budget__c
     */			
	private static void allocateToContingency(Decimal amountToDeduct) {
		List<Budgets__c> l = new List<Budgets__c>([select Id, 
														  Budget_Amount__c 
												   from Budgets__c 
												   where Period__c =: periodOfContingency and Budget_Area__c =: CONTINGENCY]);
		if (l.size() > 0) {
			Budgets__c contingencyBudget = l.get(0);
			if (contingencyBudget.Budget_Amount__c != null) {		 
				contingencyBudget.Budget_Amount__c -= amountToDeduct;
			} else {
				contingencyBudget.Budget_Amount__c = -amountToDeduct;
			}	
			
			sp = Database.setSavepoint(); // set save point
			
			Database.Saveresult result = Database.update(contingencyBudget, false);
			processResults(new List<Database.Saveresult> {result});
		} else {
			errorMsg = reclaimBudgetCS.Error_No_Contingency_Budget__c;
		}
	}
		
    /* 
     * Save the Budgets that were processed
     */		
	private static void saveReclaimBudget() {
		if (budgetLine != null) {
			Database.SaveResult result = Database.update(budgetLine, false);
			processResults(new List<Database.Saveresult> {result});
			if (errorMsg != '') Database.rollback(sp); 
		}
		if (programBudget != null && errorMsg == '') {
			Database.SaveResult result = Database.update(programBudget, false);
			processResults(new List<Database.Saveresult> {result});
			if (errorMsg != '') Database.rollback(sp); 		
		}
		if (budgetOwner != null && errorMsg == '') {
			Database.SaveResult result = Database.update(budgetOwner, false);
			processResults(new List<Database.Saveresult> {result});
			if (errorMsg != '') Database.rollback(sp); 				
		}
	}

    /* Process the result of the previous update / If there are errors then it updates the errorMsg variable
     *
     * @param result the result of the previous update
     */				
	private static void processResults(Database.SaveResult[] results) {
	    for (Database.Saveresult result : results) {
		    if (!result.success) {
		    	errorMsg = reclaimBudgetCS.Error_Request_Can_Not_Be_Processed__c;
		        if (result.getErrors() != null) {
		        	for (Database.Error error : result.getErrors()) {
		                errorMsg += error.getMessage();
		                errorMsg += '<br/>';
		        	}
		        }
		        else {
		            errorMsg += reclaimBudgetCS.Error_Updating__c;
		        }
		    }
	    }		
	}
	
    /* Record the transaction in Reclaimed_Transaction__c object
     *
     * @param amount the amount that was deducted from the Budgets
     * @param reason the reason given by the user explaining why this action needed to be performed.
     */				
	private static void recordTransaction(Decimal amount, String reason) {
		List<Reclaimed_Transaction__c> reclaimedTransactions = new List<Reclaimed_Transaction__c>();
		if (budgetsToRecord.size() > 0) {
			// Iterates through the records that were updated and creates a Reclaimed_Transacion__c for each one
			//fix this custom label
			System.debug('### TORECORD: ' + budgetsToRecord);
			for (BudgetGeneric b : budgetsToRecord) {
				Reclaimed_Transaction__c rt = new Reclaimed_Transaction__c(Name = b.name + ' - ' + Datetime.now().format('M/dd/yyyy h:mm aaa'),
																		   Budget_Id__c = b.id,
																		   Budget_URL__c = 'Label.DomainHost' + b.id,
																		   Budget_Name__c = b.name,
																		   Budget_Level__c = b.level, 
																		   User__c = UserInfo.getUserId(), 
																		   Amount__c = amount, Reason__c = reason, Date__c = Date.today());
				reclaimedTransactions.add(rt); 
			}
			budgetsToRecord.clear();
		}
		if (reclaimedTransactions.size() > 0) {
			Database.Saveresult[] results =  Database.insert(reclaimedTransactions, false);
			processResults(results);
			if (errorMsg != '') Database.rollback(sp);
		}	 
	}

  
	public class BudgetGeneric {
		public String id {get;set;}
		public String name {get;set;}
		public String level {get;set;}
		
		public BudgetGeneric(String id, String name, String level) {
			this.id = id;
			this.name = name;
			this.level = level;
		}
	}
}