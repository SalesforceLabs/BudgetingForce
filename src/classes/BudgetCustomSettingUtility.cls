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

/* This class provides methods to manage the ReclaimBudgetCS custom setting
 *
 */

public class BudgetCustomSettingUtility {
	
	private static ReclaimBudgetCS__c setting = ReclaimBudgetCS__c.getInstance();
		
	public static void loadCustomSettingForTest() {
		if (setting == null) {
			upsert new ReclaimBudgetCS__c ( SetupOwnerId = Userinfo.getOrganizationId(),
										    FYEnd__c = Date.parse('1/31/2011'),
										    FYStart__c = Date.parse('2/1/2010'),
										    Q1End__c = Date.parse('4/30/2010'),
										    Q1Start__c = Date.parse('2/1/2010'),
										    Q2End__c = Date.parse('7/31/2010'),
										    Q2Start__c = Date.parse('5/1/2010'),
										    Q3End__c = Date.parse('10/31/2010'),
										    Q3Start__c = Date.parse('8/1/2010'),
										    Q4End__c = Date.parse('1/31/2011'),
										    Q4Start__c = Date.parse('11/1/2010'),
										    Error_Amount_Must_Be_Greater_Than_Zero__c = 'Amount must be greater than zero.', 
											Error_Amount_must_not_be_empty__c = 'Amount must not be empty.', 
											Error_Budget_Line_Level_2__c = 'Uncommited Approved budget must be greater than zero.', 
											Error_Budget_Line_Level_3__c = 'There is no Budget Line for the id specified.', 
											Error_Budget_Line_Level__c = 'Amount to deduct can not be greater than Uncommited Approved Budget.', 
											Error_Budget_Owner_Level_2__c = 'Budget Remaining must be greater than zero.', 
											Error_Budget_Owner_Level_3__c = 'There is no Budget Owner for the id specified.', 
											Error_Budget_Owner_Level__c = 'Amount to deduct can not be greater than Unallocated Program Budget Amount.', 
											Error_Enter_A_Valid_Amount_Number__c = 'Please enter a valid amount number.', 
											Error_Indicate_level__c = 'You need a Budget Line, Program Budget, or Budget Owner to deduct from.', 
											Error_No_Contingency_Budget__c = 'There is not a Contingency Budget for that period. Please create one and retry your process.', 
											Error_Program_Budget_Level_2__c = 'Approved Budget Remaining must be greater than zero.', 
											Error_Program_Budget_Level_3__c = 'There is no Program Budget for the id specified.', 
											Error_Program_Budget_Level__c = 'Amount to deduct can not be greater than Unallocated Budget Line Amount.', 
											Error_Request_Can_Not_Be_Processed__c = 'Your request can not be processed due to the following errors: <br/>', 
											Error_Updating__c = 'Error updating, but there was no error message\n', 
											ManagerNoteInUI1__c = 'NOTE: if you are moving money between budgets always reduce your lowest budget line and save before reducing its parent budget.', 
											Public_Group_Allowed__c = 'Budgeting Ops Admin', 
											User_Not_Allowed_To_Reclaim__c = 'This function is not available to your user.');
		}
	}
	
    static testMethod void testReclaimBudgetCSsetting() {
    	
    	if (BudgetCustomSettingUtility.setting != null) {
    		System.debug('### Found settings - deleting them...');
    		delete [select Id from ReclaimBudgetCS__c];
    		// Check if the setting is null
    		BudgetCustomSettingUtility.setting = ReclaimBudgetCS__c.getInstance();
    		BudgetCustomSettingUtility.loadCustomSettingForTest();
    		System.assertNotEquals(null, ReclaimBudgetCS__c.getInstance());
    	} else {
    		System.debug('### No settings, okay');
    	}
    }			     				
}