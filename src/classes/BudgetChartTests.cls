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

@isTest
private class BudgetChartTests {
	
	static testMethod void testBudgetsCharts(){
		Period__c parentPeriod = new Period__c(Type__c = 'Year', Number__c = Decimal.valueOf('2050'));
		insert parentPeriod;
		System.assertNotEquals(null, parentPeriod.Id);
		Period__c p = new Period__c(parentPeriod__c = parentPeriod.Id, Type__c = 'Quarter', Number__c = Decimal.valueOf('4'));
		insert p;
		System.assertNotEquals(null, p.Id);
	
		// insert budget
		Budgets__c budgets = new Budgets__c(Period__c = p.Id, Name = 'Chart test', Budget_Amount__c = Decimal.valueOf('1000'));
		insert budgets;
		System.assertNotEquals(null, budgets.Id);
		// insert program budgets
		Program_Budget__c pb1 = new Program_Budget__c(Budget_Owner__c = budgets.Id, Budget_Area__c = 'test1', Program_Type__c = 'test1', Program_Budget_Amount__c = Decimal.valueOf('100'));
		Program_Budget__c pb2 = new Program_Budget__c(Budget_Owner__c = budgets.Id, Budget_Area__c = 'test2', Program_Type__c = 'test2', Program_Budget_Amount__c = Decimal.valueOf('200'));
		Program_Budget__c pb3 = new Program_Budget__c(Budget_Owner__c = budgets.Id, Budget_Area__c = 'test3', Program_Type__c = 'test3', Program_Budget_Amount__c = Decimal.valueOf('300'));
		insert new List<Program_Budget__c> {pb1,pb2,pb3};
		System.assertNotEquals(null, pb1.Id);
		System.assertNotEquals(null, pb2.Id);
		System.assertNotEquals(null, pb3.Id);
		
		System.assert(budgets.id != null);
		ApexPages.StandardController stdCtl = new ApexPages.StandardController(budgets);
		BudgetOwnerChartController ctl = new BudgetOwnerChartController(stdCtl);
		System.assertEquals(ctl.budgetOwner.Id , budgets.Id);
		System.assertEquals(ctl.programBudgets.size(), 3);
		
		Decimal spendings = pb1.Program_Budget_Amount__c + pb2.Program_Budget_Amount__c + pb3.Program_Budget_Amount__c;
		System.assertEquals(ctl.spendings, spendings);
		System.assertEquals(ctl.savings, ctl.budgetOwner.Budget_Amount__c - spendings);
	}
	
	static testMethod void testBudgetChartAmountNull() {
		Period__c parentPeriod = new Period__c(Type__c = 'Year', Number__c = Decimal.valueOf('2050'));
		insert parentPeriod;
		System.assertNotEquals(null, parentPeriod.Id);
		Period__c p = new Period__c(parentPeriod__c = parentPeriod.Id, Type__c = 'Quarter', Number__c = Decimal.valueOf('4'));
		insert p;
		System.assertNotEquals(null, p.Id);
	
		// insert budget
		Budgets__c budgets = new Budgets__c(Period__c = p.Id, Name = 'Chart test');
		insert budgets;
		System.assertNotEquals(null, budgets.Id);

		System.assert(budgets.id != null);
		ApexPages.StandardController stdCtl = new ApexPages.StandardController(budgets);
		BudgetOwnerChartController ctl = new BudgetOwnerChartController(stdCtl);
		System.assertEquals(ctl.budgetOwner.Id , budgets.Id);
		
		System.assertEquals(ctl.spendings, 0);
		System.assertEquals(ctl.savings, 0);	
	}
	
	static testMethod void testProgramBudgetChart(){
		Period__c parentPeriod = new Period__c(Type__c = 'Year', Number__c = Decimal.valueOf('2050'));
		insert parentPeriod;
		System.assertNotEquals(null, parentPeriod.Id);
		Period__c p = new Period__c(parentPeriod__c = parentPeriod.Id, Type__c = 'Quarter', Number__c = Decimal.valueOf('4'));
		insert p;
		System.assertNotEquals(null, p.Id);
	
		// insert budget
		Budgets__c budgets = new Budgets__c(Period__c = p.Id, Name = 'Chart test', Budget_Amount__c = Decimal.valueOf('1000'));
		insert budgets;
		System.assertNotEquals(null, budgets.Id);
		// insert program budgets
		Program_Budget__c pb = new Program_Budget__c(Budget_Owner__c = budgets.Id, Budget_Area__c = 'test1', Program_Type__c = 'test1', Program_Budget_Amount__c = Decimal.valueOf('500'));
		insert pb;
		System.assertNotEquals(null, pb.Id);
		// insert budget lines
		Budget_Line__c bl1 = new Budget_Line__c(Program_Budget__c = pb.Id, Budget_Line_Amount__c = Decimal.valueOf('50'));
		Budget_Line__c bl2 = new Budget_Line__c(Program_Budget__c = pb.Id, Budget_Line_Amount__c = Decimal.valueOf('100'));
		Budget_Line__c bl3 = new Budget_Line__c(Program_Budget__c = pb.Id, Budget_Line_Amount__c = Decimal.valueOf('150'));
		insert new List<Budget_Line__c> {bl1,bl2,bl3};
		System.assertNotEquals(null, bl1.Id);
		System.assertNotEquals(null, bl2.Id);
		System.assertNotEquals(null, bl3.Id);
		
		ApexPages.StandardController stdCtl = new ApexPages.StandardController(pb);
		ProgramBudgetChartController ctl = new ProgramBudgetChartController(stdCtl);
		System.assertEquals(ctl.programBudget.Id, pb.Id);
		Decimal spendings = bl1.Budget_Line_Amount__c + bl2.Budget_Line_Amount__c + bl3.Budget_Line_Amount__c;
		System.assertEquals(ctl.spendings, spendings);
		System.assertEquals(ctl.savings, ctl.programBudget.Program_Budget_Amount__c - spendings);
	}
	
	static testMethod void testProgramBudgetChartAmountNull() {
		Period__c parentPeriod = new Period__c(Type__c = 'Year', Number__c = Decimal.valueOf('2050'));
		insert parentPeriod;
		System.assertNotEquals(null, parentPeriod.Id);
		Period__c p = new Period__c(parentPeriod__c = parentPeriod.Id, Type__c = 'Quarter', Number__c = Decimal.valueOf('4'));
		insert p;
		System.assertNotEquals(null, p.Id);
	
		// insert budget
		Budgets__c budgets = new Budgets__c(Period__c = p.Id, Name = 'Chart test', Budget_Amount__c = Decimal.valueOf('1000'));
		insert budgets;
		System.assertNotEquals(null, budgets.Id);
		// insert program budgets
		Program_Budget__c pb = new Program_Budget__c(Budget_Owner__c = budgets.Id, Budget_Area__c = 'test1', Program_Type__c = 'test1');
		insert pb;
		System.assertNotEquals(null, pb.Id);	

		ApexPages.StandardController stdCtl = new ApexPages.StandardController(pb);
		ProgramBudgetChartController ctl = new ProgramBudgetChartController(stdCtl);
		System.assertEquals(ctl.programBudget.Id, pb.Id);
		System.assertEquals(ctl.spendings, 0);
		System.assertEquals(ctl.savings, 0);
	}
	
	/*
	 * GUS ID: W-799610
	 * Pending Review: Guillermo Freire, Santiago Doval, Angelica Buffa
	 */
	static testMethod void testBudgetLineChart() {
		Period__c parentPeriod = new Period__c(Type__c = 'Year', Number__c = Decimal.valueOf('2050'));
		insert parentPeriod;
		System.assertNotEquals(null, parentPeriod.Id);
		Period__c p = new Period__c(parentPeriod__c = parentPeriod.Id, Type__c = 'Quarter', Number__c = Decimal.valueOf('4'));
		insert p;
		System.assertNotEquals(null, p.Id);
	
		// insert budget
		Budgets__c budgets = new Budgets__c(Period__c = p.Id, Name = 'Chart test', Budget_Amount__c = Decimal.valueOf('1000'));
		insert budgets;
		System.assertNotEquals(null, budgets.Id);
		// insert program budgets
		Program_Budget__c pb = new Program_Budget__c(Budget_Owner__c = budgets.Id, Budget_Area__c = 'test1', Program_Type__c = 'test1', Program_Budget_Amount__c = Decimal.valueOf('500'));
		insert pb;
		System.assertNotEquals(null, pb.Id);
		// insert budget lines
		Budget_Line__c bl = new Budget_Line__c(Program_Budget__c = pb.Id, Budget_Line_Amount__c = Decimal.valueOf('400'));
		insert bl;
		System.assertNotEquals(null, bl.Id);
		
		// insert purchase requests
		Purchase_Request__c pr1 = new Purchase_Request__c(Budget_Line__c = bl.Id, Month_1_Amt__c = Decimal.valueOf('10'), Month_2_Amt__c = Decimal.valueOf('10'), Month_3_Amt__c = Decimal.valueOf('30'), Purchase_Request_Amount__c = Decimal.valueOf('50'), Status__c = 'New/Not Submitted');
		Purchase_Request__c pr2 = new Purchase_Request__c(Budget_Line__c = bl.Id, Month_1_Amt__c = Decimal.valueOf('10'), Month_2_Amt__c = Decimal.valueOf('10'), Month_3_Amt__c = Decimal.valueOf('40'), Purchase_Request_Amount__c = Decimal.valueOf('60'), Status__c = 'New/Not Submitted');
		Purchase_Request__c pr3 = new Purchase_Request__c(Budget_Line__c = bl.Id, Month_1_Amt__c = Decimal.valueOf('10'), Month_2_Amt__c = Decimal.valueOf('10'), Month_3_Amt__c = Decimal.valueOf('50'), Purchase_Request_Amount__c = Decimal.valueOf('70'), Status__c = 'New/Not Submitted');
		insert new List<Purchase_Request__c> {pr1,pr2,pr3};
		System.assertNotEquals(null, pr1.Id);
		System.assertNotEquals(null, pr2.Id);
		System.assertNotEquals(null, pr3.Id);
		
		ApexPages.StandardController stdCtl = new ApexPages.StandardController(bl);
		BudgetLineChartController ctl = new BudgetLineChartController(stdCtl);
		System.assertEquals(ctl.budgetLine.Id, bl.Id);
		System.assertEquals(ctl.purchaseRequests.size(), 3);
		// Check that the variables were loaded with the proper values
		Decimal spendings = pr1.Purchase_Request_Amount__c + pr2.Purchase_Request_Amount__c + pr3.Purchase_Request_Amount__c;
		System.assertEquals(ctl.spendings, spendings);
		System.assertEquals(ctl.savings, ctl.budgetLine.Budget_Line_Amount__c - spendings);
	}
	
	/*
	 * GUS ID: W-799610
	 * Pending Review: Guillermo Freire, Santiago Doval, Angelica Buffa
	 */	
	static testMethod void testBudgetLineCharAmountNull() {
		Period__c parentPeriod = new Period__c(Type__c = 'Year', Number__c = Decimal.valueOf('2050'));
		insert parentPeriod;
		System.assertNotEquals(null, parentPeriod.Id);
		Period__c p = new Period__c(parentPeriod__c = parentPeriod.Id, Type__c = 'Quarter', Number__c = Decimal.valueOf('4'));
		insert p;
		System.assertNotEquals(null, p.Id);
	
		// insert budget
		Budgets__c budgets = new Budgets__c(Period__c = p.Id, Name = 'Chart test', Budget_Amount__c = Decimal.valueOf('1000'));
		insert budgets;
		System.assertNotEquals(null, budgets.Id);
		// insert program budgets
		Program_Budget__c pb = new Program_Budget__c(Budget_Owner__c = budgets.Id, Budget_Area__c = 'test1', Program_Type__c = 'test1', Program_Budget_Amount__c = Decimal.valueOf('500'));
		insert pb;
		System.assertNotEquals(null, pb.Id);
		// insert budget lines
		Budget_Line__c bl = new Budget_Line__c(Program_Budget__c = pb.Id);
		insert bl;
		System.assertNotEquals(null, bl.Id);

		ApexPages.StandardController stdCtl = new ApexPages.StandardController(bl);
		BudgetLineChartController ctl = new BudgetLineChartController(stdCtl);
		System.assertEquals(ctl.budgetLine.Id, bl.Id);
		System.assertEquals(ctl.spendings, 0);
		System.assertEquals(ctl.savings, 0);		
	}
}