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
private class BudgetManagerControllerUnitTest {

	static List<SObject> createData() {
		// Retrieve period
		Period__c p = [select Id from Period__c limit 1].get(0);
		
		// Create Budgets
		Budgets__c budgetOwner = new Budgets__c(Period__c = p.Id, 
											    Budget_Owner__c = 'testing budget user', 
											    Budget_Amount__c = BudgetUtil.parseDecimal('10000'));
		insert budgetOwner;
		System.assertNotEquals(null, budgetOwner.Id);
		
		Program_Budget__c programBudget = new Program_Budget__c(Budget_Owner__c = budgetOwner.Id, 
															    Short_Name__c = 'dftesting', 
															    Program_Budget_Amount__c = BudgetUtil.parseDecimal('5000'));
		insert programBudget;
		System.assertNotEquals(null, programBudget.Id);
		
		Budget_Line__c budgetLine = new Budget_Line__c(Program_Budget__c = programBudget.Id, 
													   Short_Name__c = 'dftesting', 
													   Recurring__c = false, 
													   Budget_Line_Amount__c = BudgetUtil.parseDecimal('2000'));
		insert budgetLine;
		System.assertNotEquals(null, budgetLine.Id);
				
		Purchase_Request__c purchaseRequest = new Purchase_Request__c(Budget_Line__c = budgetLine.Id, 
																	  Name = 'prtest1', 
																	  Status__c = 'New/Not Submitted',
																	  Month_1_Amt__c = BudgetUtil.parseDecimal('300'), 
																	  Month_2_Amt__c = BudgetUtil.parseDecimal('300'), 
																	  Month_3_Amt__c = BudgetUtil.parseDecimal('400'), 
																	  Purchase_Request_Amount__c = BudgetUtil.parseDecimal('1000'));
		insert purchaseRequest;
		System.assertNotEquals(null, purchaseRequest.Id);
		
		return new List<SObject> {p, budgetOwner, programBudget, budgetLine, purchaseRequest};	
	}

	private static List<BudgetNode> createTreeForTest(BudgetManagerController bmc) { 
		// We verified that all the lists were loaded correctly
		System.assert(bmc.periodsList.size() > 0);
		System.assert(bmc.budgetAreaList.size() > 0);
		System.assert(bmc.regionsList.size() > 0);
		System.assert(bmc.planBudgetCodesList.size() > 0);
		System.assert(bmc.recurringList.size() > 0);

		// Add a Budget Owner
		Integer bnl1GenId = bmc.i; // Id generated automatically when we add a node
		bmc.parentNode = '';
		bmc.level1BudgetPeriod = bmc.periodsList.get(0).getValue();
		bmc.level1BudgetArea = 'DiegoFeblesTest';
		bmc.addNode();
	
		
		// Add a Program Budget
		Integer bnl2GenId = bmc.i; // Id generated automatically when we add a node
		bmc.parentNode = bnl1GenId.format(); // Assign this Program Budget to the Budget Owner previously created
		bmc.level3BudgetShortName = 'programbudgettest';
		bmc.level3BudgetOwner = 'Owner Test 1';
		bmc.level3BudgetPlanBudget = bmc.planBudgetCodesList.get(0).getValue();
		bmc.addNode();
		
		// Add a Budget Line
		Integer bnl3GenId = bmc.i; // Id generated automatically when we add a node
		bmc.parentNode = bnl2GenId.format(); // Assign this Budget Line to the Program Budget previously created
		bmc.level4BudgetShortName = 'budgetlinetest';
		bmc.level4BudgetRegion = bmc.regionsList.get(1).getValue();
		bmc.level4BudgetDepartment = bmc.departmentsList.get(1).getValue();
		bmc.level4BudgetDescription = 'Description Test';
		bmc.level4BudgetLineAmount = '0';
		bmc.addNode();
		
		bmc.saveTree();
				
		// Level 1
		BudgetNode bnl1 = bmc.budgetNodesMap.get(bnl1GenId);
		System.assertNotEquals(null, bnl1);
		System.assertNotEquals(null, bnl1.objId);
		
		// Level 2
		BudgetNode bnl2 = bmc.budgetNodesMap.get(bnl2GenId);
		System.assertNotEquals(null, bnl1);
		System.assertNotEquals(null, bnl2.objId);
		// Check that the Program Budget was assigned to the Budget Owner
		System.assertEquals(bnl1.objId, ((ProgramBudget)bnl2).obj.Budget_Owner__c);

		// Level 3
		BudgetNode bnl3 = bmc.budgetNodesMap.get(bnl3GenId);
		System.assertNotEquals(null, bnl1);
		System.assertNotEquals(null, bnl3.objId);
		// Check that the Budget Line was assigned to the Program Budget
		System.assertEquals(bnl2.objId, ((BudgetLine)bnl3).obj.Program_Budget__c); 
		 
		// Insert purchase requests
		Purchase_Request__c pr1 = new Purchase_Request__c(Name = 'prtest1', Purchase_Request_Amount__c = 0, Budget_Line__c = ((BudgetLine)bnl3).obj.Id, Status__c = 'New/Not Submitted');
		Purchase_Request__c pr2 = new Purchase_Request__c(Name = 'prtest2', Purchase_Request_Amount__c = 0, Budget_Line__c = ((BudgetLine)bnl3).obj.Id, Status__c = 'New/Not Submitted');
		Purchase_Request__c pr3 = new Purchase_Request__c(Name = 'prtest3', Purchase_Request_Amount__c = 0, Budget_Line__c = ((BudgetLine)bnl3).obj.Id, Status__c = 'New/Not Submitted');
		insert new List<Purchase_Request__c> {pr1, pr2, pr3};
		 
		BudgetNode pr1Node = new PurchaseRequest(bmc.i++, pr1);
		BudgetNode pr2Node = new PurchaseRequest(bmc.i++, pr2);
		BudgetNode pr3Node = new PurchaseRequest(bmc.i++, pr3);
		bnl3.add(pr1Node);
		bnl3.add(pr2Node);
		bnl3.add(pr3Node);
				
		return new List<BudgetNode> { bnl1, bnl2, bnl3};	
	}	

    private static void createPeriods() {
    	// Delete existent periods so we can use just the periods created for the test methods.
    	delete [select Id from Period__c];
    	
		Period__c parentPeriod = new Period__c(Type__c = 'Year', Number__c = Decimal.valueOf('2050'));
		insert parentPeriod;
		System.assertNotEquals(null, parentPeriod.Id);
		Period__c p1 = new Period__c(parentPeriod__c = parentPeriod.Id, Type__c = 'Quarter', Number__c = Decimal.valueOf('1'));
		Period__c p2 = new Period__c(parentPeriod__c = parentPeriod.Id, Type__c = 'Quarter', Number__c = Decimal.valueOf('2'));
		insert new List<Period__c> {p1,p2};    
		System.assertNotEquals(null, p1.Id);
		System.assertNotEquals(null, p2.Id);
    }

	private static void loadCustomSetting() {
		BudgetCustomSettingUtility.loadCustomSettingForTest();		
	}

	public static testMethod void testNoPeriods(){
		loadCustomSetting();
		
		delete [Select id from Period__c];
		BudgetManagerController ctl = new BudgetManagerController();
		ctl.install();
		System.assertEquals(5,[Select count() from Period__c]);
	}

	static testMethod void testFlow() {
		createPeriods();		
				
		BudgetManagerController bmc = new BudgetManagerController();
		
		List<BudgetNode> nodes = createTreeForTest(bmc);
		BudgetNode bnl1 = nodes.get(0);
		BudgetNode bnl2 = nodes.get(1);
		BudgetNode bnl3 = nodes.get(2);
		
		// Test filterTree
		bmc.currentPeriod = bmc.periodsList.get(0).getValue();
		bmc.currentBudgetArea = new List<String> { 'DiegoFeblesTest' };
		bmc.filterTree();
		Integer countBO = 0; // Budget Owners counter
		Integer countPB = 0; // Program Budgets counter
		Integer countBL = 0; // Budget Lines counter
		Integer countPR = 0; // Purchase Request counter
		
		// We iterate over the tree 
		for (BudgetNode a : bmc.tree.children) {
			countBO++;
			for (BudgetNode b : a.children) {
				countPB++;
				for (BudgetNode c : b.children) {
					countBL++;
					for (BudgetNode d : c.children) {
						countPR++;
					}
				}
			}
		}
		
		System.assertEquals(1, countBO); // We should have only one Budget Owner
		System.assertEquals(1, countPB); // We should have only one Program Budget
		System.assertEquals(1, countBL); // We should have only one Budget Line
		System.assertEquals(3, countPR); // We should have three purchase requests

		// Retrieves Budget Owner, Program Budget, and Budget Line from the database
		Budgets__c bl1 = [select Id, Name from Budgets__c where Id =: bnl1.objId];
		Program_Budget__c bl2 = [select Id, Name, Budget_Owner__c from Program_Budget__c where Id =: bnl2.objId];
		Budget_Line__c bl3 = [select Id, Name, Program_Budget__c, (select Name from Purchase_Requests1__r) from Budget_Line__c where Id =: bnl3.objId];
		System.assertEquals(bnl1.objId, bl1.Id);
		System.assertEquals(bnl2.objId, bl2.Id);
		System.assertEquals(bnl3.objId, bl3.Id);
		// Test that the Budget Owner Name was generated automatically (workflow)
		System.assertEquals(bmc.periodsList.get(0).getLabel() + ' ' + bmc.level1BudgetArea, bl1.Name);
		// Test that the Program Budget Name was generated automatically (workflow) 
		System.assertEquals(bl1.Name + ': ' + bmc.level3BudgetPlanBudget + (bmc.level3BudgetShortName == '' ? '' : ': ' + bmc.level3BudgetShortName), bl2.Name);
		// Test proper association between bl1, bl2, bl3
		System.assertEquals(bl1.Id, bl2.Budget_Owner__c);
		System.assertEquals(bl2.Id, bl3.Program_Budget__c);
		// Test that we have 3 purchase requests for bl3
		System.assertEquals(3, bl3.Purchase_Requests1__r.size());
		
		// Test changeReadOnly
		System.assertEquals(true, bmc.readOnly);
		bmc.changeReadOnly();
		System.assertEquals(false, bmc.readOnly);		
	}
	
    /*
     * Method: testBudget()
     * 
	 * GUS-Id : 799608
	 * Modified by: Santiago Doval 7/19/10
	 * Pending review: Pablo Vigil, Guillermo Freire, Diego Febles, Angelica Buffa 
     */
    static testMethod void testBudget() {
		createPeriods();
		
		BudgetManagerController bmc = new BudgetManagerController();
		
		List<BudgetNode> nodes = createTreeForTest(bmc);
		BudgetNode bnl1 = nodes.get(0);
		BudgetNode bnl2 = nodes.get(1);
		BudgetNode bnl3 = nodes.get(2);
		
		// Test if the nodes were saved to the database, if they were, then isNew returns false. If they weren't then isNew returns true
		System.assertEquals(false, bnl1.isNew); // bnl1 was saved
		System.assertEquals(false, bnl2.isNew); // bnl2 was saved
		System.assertEquals(false, bnl3.isNew); // bnl3 was saved
		
		// We are going to test Approved, Requested, ApprovedTotal, RequestedTotal
		
		// We create 1 more Program Budget
		Integer bnl2_2GenId = bmc.i; // Id generated automatically when we add a node
		bmc.parentNode = bnl1.Id.format(); // Assign this Program Budget to the Budget Owner previously created
		bmc.level3BudgetOwner = 'Owner Test 2';
		bmc.level3BudgetPlanBudget = bmc.planBudgetCodesList.get(1).getValue();
		bmc.addNode();
		
		BudgetNode bnl2_2 = bmc.budgetNodesMap.get(bnl2_2GenId);
		
		// We create 2 more Budget Lines and assign them to the first Program Budget
		Integer bnl3_2GenId = bmc.i; // Id generated automatically when we add a node
		bmc.parentNode = bnl2.Id.format(); // Assign this Budget Line to the first Program Budget
		bmc.level4BudgetShortName = 'budgetlinetest2';
		bmc.level4BudgetRegion = bmc.regionsList.get(1).getValue();
		bmc.level4BudgetDepartment = bmc.departmentsList.get(1).getValue();
		bmc.level4BudgetDescription = 'Description Test';
		bmc.level4BudgetLineAmount = '0';		
		bmc.addNode();		
	
		Integer bnl3_3GenId = bmc.i; // Id generated automatically when we add a node
		bmc.parentNode = bnl2.Id.format(); // Assign this Budget Line to the first Program Budget
		bmc.level4BudgetShortName = 'budgetlinetest3';
		bmc.level4BudgetRegion = bmc.regionsList.get(1).getValue();
		bmc.level4BudgetDepartment = bmc.departmentsList.get(1).getValue();
		bmc.level4BudgetDescription = 'Description Test';
		bmc.level4BudgetLineAmount = '0';		
		bmc.addNode();	
		
		// We create 2 more Budget Lines and assign them to the second Program Budget
		Integer bnl3_4GenId = bmc.i; // Id generated automatically when we add a node
		bmc.parentNode = bnl2_2.Id.format(); // Assign this Budget Line to the second Program Budget  
		bmc.level4BudgetShortName = 'budgetlinetest4';
		bmc.level4BudgetRegion = bmc.regionsList.get(1).getValue();
		bmc.level4BudgetDepartment = bmc.departmentsList.get(1).getValue();
		bmc.level4BudgetDescription = 'Description Test';
		bmc.level4BudgetLineAmount = '0';		
		bmc.addNode();	
	
		Integer bnl3_5GenId = bmc.i; // Id generated automatically when we add a node
		bmc.parentNode = bnl2_2.Id.format(); // Assign this Budget Line to the second Program Budget
		bmc.level4BudgetShortName = 'budgetlinetest5';
		bmc.level4BudgetRegion = bmc.regionsList.get(1).getValue();
		bmc.level4BudgetDepartment = bmc.departmentsList.get(1).getValue();
		bmc.level4BudgetDescription = 'Description Test';
		bmc.level4BudgetLineAmount = '0';		
		bmc.addNode();	
		
		BudgetNode bnl3_2 = bmc.budgetNodesMap.get(bnl3_2GenId);
		BudgetNode bnl3_3 = bmc.budgetNodesMap.get(bnl3_3GenId);		
		BudgetNode bnl3_4 = bmc.budgetNodesMap.get(bnl3_4GenId);
		BudgetNode bnl3_5 = bmc.budgetNodesMap.get(bnl3_5GenId);
		
		// Test if the nodes were saved to the database, if they were, then isNew returns false. If they weren't then isNew returns true
		System.assertEquals(true, bnl3_2.isNew); // bnl3_2 is not saved yet
		System.assertEquals(true, bnl3_3.isNew); // bnl3_3 is not saved yet
		System.assertEquals(true, bnl3_4.isNew); // bnl3_4 is not saved yet
		System.assertEquals(true, bnl3_5.isNew); // bnl3_5 is not saved yet
		
		bmc.saveTree();	
		
		System.assertEquals(false, bnl3_2.isNew); // bnl3_2 is not saved yet
		System.assertEquals(false, bnl3_3.isNew); // bnl3_3 is not saved yet
		System.assertEquals(false, bnl3_4.isNew); // bnl3_4 is not saved yet
		System.assertEquals(false, bnl3_5.isNew); // bnl3_5 is not saved yet
		
		// Check that Program Budget was inserted into the database
		System.assertNotEquals(null, bnl1);
		System.assertNotEquals(null, bnl2_2.objId);
		// Check that the Program Budget was assigned to the Budget Owner
		System.assertEquals(bnl1.objId, ((ProgramBudget)bnl2_2).obj.Budget_Owner__c);
		
		System.assertNotEquals(null, bnl3_2);
		System.assertNotEquals(null, bnl3_2.objId);
		// Check that the Budget Line was assigned to the Program Budget
		System.assertEquals(bnl2.objId, ((BudgetLine)bnl3_2).obj.Program_Budget__c);

		System.assertNotEquals(null, bnl3_3);
		System.assertNotEquals(null, bnl3_3.objId);
		// Check that the Budget Line was assigned to the Program Budget
		System.assertEquals(bnl2.objId, ((BudgetLine)bnl3_3).obj.Program_Budget__c);
		
		System.assertNotEquals(null, bnl3_4);
		System.assertNotEquals(null, bnl3_4.objId);
		// Check that the Budget Line was assigned to the Program Budget
		System.assertEquals(bnl2_2.objId, ((BudgetLine)bnl3_4).obj.Program_Budget__c);

		System.assertNotEquals(null, bnl3_5);
		System.assertNotEquals(null, bnl3_5.objId);
		// Check that the Budget Line was assigned to the Program Budget
		System.assertEquals(bnl2_2.objId, ((BudgetLine)bnl3_5).obj.Program_Budget__c);
		
		bmc.parentNode = '';
		bmc.level1BudgetPeriod = bmc.periodsList.get(0).getValue();
		bmc.level1BudgetArea = 'DiegoFeblesTest';
		
		// Check names
		System.assertEquals(bnl1.Name, bnl1.name);
		System.assertEquals(bnl2.Name, bnl2.name);
		System.assertEquals(bnl3.Name, bnl3.name);
		
		// Test purchase requests for bnl3
		BudgetNode bnl4_1 = bnl3.children.get(0);
		BudgetNode bnl4_2 = bnl3.children.get(1);
		BudgetNode bnl4_3 = bnl3.children.get(2);
		
		System.assertEquals('prtest1', ((PurchaseRequest)bnl4_1).name);
		System.assertEquals('prtest2', ((PurchaseRequest)bnl4_2).name);
		System.assertEquals('prtest3', ((PurchaseRequest)bnl4_3).name);
				
		// Test approvedS, requestedS, approvedTotalS, requestedTotalS for each node
		System.assertEquals('0.00', bnl1.approvedS);
		System.assertEquals('0.00', bnl1.requestedS);
		System.assertEquals('0.00', bnl1.approvedTotalS);
		System.assertEquals('0.00', bnl2.approvedS);
		System.assertEquals('0.00', bnl2.requestedS);
		System.assertEquals('0.00', bnl2.approvedTotalS);
		System.assertEquals('0.00', bnl3.approvedS);
		System.assertEquals('0.00', bnl3.approvedTotalS);
		System.assertEquals('0.00', bnl3_2.approvedS);
		System.assertEquals('0.00', bnl3_2.approvedTotalS);
		System.assertEquals('0.00', bnl3_3.approvedS);
		System.assertEquals('0.00', bnl3_3.requestedS);
		System.assertEquals('0.00', bnl3_3.approvedTotalS);
		System.assertEquals('0.00', bnl3_4.approvedS);
		System.assertEquals('0.00', bnl3_4.requestedS);
		System.assertEquals('0.00', bnl3_4.approvedTotalS);
		System.assertEquals('0.00', bnl3_5.approvedS);
		System.assertEquals('0.00', bnl3_5.requestedS);
		System.assertEquals('0.00', bnl3_5.approvedTotalS);
		System.assertEquals('0.00', bnl4_1.requestedS);
		System.assertEquals('0.00', bnl4_2.requestedS);
		System.assertEquals('0.00', bnl4_3.requestedS);		
		
		// Check levels
		System.assertEquals(1, bnl1.Level);
		System.assertEquals(2, bnl2.Level);
		System.assertEquals(3, bnl3.Level);
		System.assertEquals(3, bnl3_2.Level);
		System.assertEquals(3, bnl3_3.Level);
		System.assertEquals(3, bnl3_4.Level);
		System.assertEquals(3, bnl3_5.Level);
		System.assertEquals(4, bnl4_1.Level);
		System.assertEquals(4, bnl4_2.Level);
		System.assertEquals(4, bnl4_3.Level);
		
		// Set values for approvedS and requestedS
		bnl1.approvedS = '10000'; 
		bnl2.approvedS = '1000';
		bnl2_2.approvedS = '1000';
		bnl2_2.requestedS = '0';
		bnl3.approvedS = '100';
		bnl3.requestedS = '0';
		bnl3_2.approvedS = '100';
		bnl3_2.requestedS = '0';
		bnl3_3.approvedS = '100';
		bnl3_3.requestedS = '0';
		bnl3_4.approvedS = '100';
		bnl3_4.requestedS = '0';
		bnl3_5.approvedS = '100';
		bnl3_5.requestedS = '0';
		bnl4_1.requestedS = '0';
		bmc.saveTree();
		
		System.assertEquals((BudgetUtil.parseDecimal(bnl3.approvedS) + BudgetUtil.parseDecimal(bnl3_2.approvedS) + BudgetUtil.parseDecimal(bnl3_3.approvedS)), BudgetUtil.parseDecimal(bnl2.approvedTotalS));
		System.assertEquals((BudgetUtil.parseDecimal(bnl3_4.approvedS) + BudgetUtil.parseDecimal(bnl3_5.approvedS)), BudgetUtil.parseDecimal(bnl2_2.approvedTotalS));
		System.assertEquals((BudgetUtil.parseDecimal(bnl2.approvedS) + BudgetUtil.parseDecimal(bnl2_2.approvedS)), BudgetUtil.parseDecimal(bnl1.approvedTotalS));
		
		
		String reg =  bnl1.region;
		bnl1.approved = 3;
		bnl1.requested = bnl4_1.level;
	//	reg = bnl4_1.currencycode;
		bnl4_1.approved = bnl4_1.BLApprovedUncommitted;
		
		
	}
	
	
	static testMethod void testRecurring() {
		loadCustomSetting();
		createPeriods();
		
		// I set BudgetRecurringUtility.isTest to true, to let know we are in a test context
		BudgetRecurringUtility.isTest = true;
		
		BudgetManagerController bmc = new BudgetManagerController();
		
		BudgetPeriodUtility bpu = new BudgetPeriodUtility();
		
		List<BudgetNode> nodes = createTreeForTest(bmc);
		BudgetNode bnl1 = nodes.get(0);
		BudgetNode bnl2 = nodes.get(1);
		BudgetNode bnl3 = nodes.get(2);
				
		// Retrieves Budget Owner, Program Budget, and Budget Line from the database
		Budgets__c bl1 = [select Id, Name from Budgets__c where Id =: bnl1.objId];
		Program_Budget__c bl2 = [select Id, Name, Budget_Owner__c from Program_Budget__c where Id =: bnl2.objId];
		Budget_Line__c bl3 = [select Id, Name, Program_Budget__c from Budget_Line__c where Id =: bnl3.objId];
		//Budget_Line__c bl3_recurring = [select Id, Name, Number_of_Quarters__c, Recurring__c, Recurring_Start_Period__r.Name, Program_Budget__c from Budget_Line__c where Id =: bnl3_recurring.objId];
		System.assertEquals(bnl1.objId, bl1.Id);
		System.assertEquals(bnl2.objId, bl2.Id);
		System.assertEquals(bnl3.objId, bl3.Id);
		//System.assertEquals(bnl3_recurring.objId, bl3_recurring.Id);
		// Test that the Budget Owner Name was generated automatically (workflow)
		System.assertEquals(bmc.periodsList.get(0).getLabel() + ' ' + bmc.level1BudgetArea, bl1.Name);
		// Test that the Program Budget Name was generated automatically (workflow) 
		System.assertEquals(bl1.Name + ': ' + bmc.level3BudgetPlanBudget + (bmc.level3BudgetShortName == '' ? '' : ': ' + bmc.level3BudgetShortName), bl2.Name);
		// Test proper association between bl1, bl2, bl3
		System.assertEquals(bl1.Id, bl2.Budget_Owner__c);
		System.assertEquals(bl2.Id, bl3.Program_Budget__c);
		
		// Update bl3 to trigger recurring process
		bl3.Recurring__c = true;
		bl3.Number_of_Quarters__c = 2;
		bl3.Recurring_Start_Period__c = bmc.periodsList.get(1).getValue();
		test.startTest();
		update bl3;
		test.stopTest();
		
		// Test that the tree was also created for the following (2) quarters, starting at (level4BudgetRecurringStartPeriod).
    	
    	Period__c recurringStartPeriod = [select Id, Name, Start_Date__c, End_Date__c, Type__c, Number__c, ParentPeriod__c, ParentPeriod__r.Id, ParentPeriod__r.Name, ParentPeriod__r.Start_Date__c, ParentPeriod__r.End_Date__c, ParentPeriod__r.Type__c, ParentPeriod__r.Number__c from Period__c where Id =: bl3.Recurring_Start_Period__c limit 1][0];
		// We need the periods on which we are going to test if the tree was created
		
		List<Period__c> periods = bpu.getRecurringPeriods(recurringStartPeriod, Math.round(bl3.Number_of_Quarters__c));
		
		for (Period__c p : periods) {
			// Test that the Budget Owner was copied
    		String auxBOwnerName = bl1.Name;
			String bOwnerName = auxBOwnerName.replace(auxBOwnerName.substring(0,6), p.Name);
			Budgets__c bl1ByPeriod = [select Id, Name from Budgets__c where Name =: bOwnerName and Period__c =: p.Id];
			System.assertNotEquals(null, bl1ByPeriod.Id);
			// Test that the Program Budget was copied
			Program_Budget__c bl2ByPeriod = [select Id, Name from Program_Budget__c where Budget_Owner__c =: bl1ByPeriod.Id];
			System.assertNotEquals(null, bl2ByPeriod.Id);
			// Test that the Budget Line was copied
			Budget_Line__c bl3ByPeriod = [select Id, Name from Budget_Line__c where Program_Budget__c =: bl2ByPeriod.Id];
			System.assertNotEquals(null, bl3ByPeriod.Id);
		}	
	}
	
	
	
	static testMethod void testRecurringBudgetOwnerExist() {
		loadCustomSetting();
		createPeriods();

		// I set BudgetRecurringUtility.isTest to true, to let know we are in a test context
		BudgetRecurringUtility.isTest = true;
		
		BudgetManagerController bmc = new BudgetManagerController();
		
		BudgetPeriodUtility bpu = new BudgetPeriodUtility();

		List<BudgetNode> nodes = createTreeForTest(bmc);
		BudgetNode bnl1 = nodes.get(0);
		BudgetNode bnl2 = nodes.get(1);
		BudgetNode bnl3 = nodes.get(2);
		
		// We create a Budget Owner for a different period (bmc.periodsList.get(1).getValue()) and copy the values of the Budget Owner (bnl1) 
		Integer bnl1_1GenId = bmc.i; // Id generated automatically when we add a node
		bmc.parentNode = '';
		bmc.level1BudgetPeriod = bmc.periodsList.get(1).getValue();
		bmc.level1BudgetArea = 'DiegoFeblesTest';
		bmc.addNode();
		bmc.saveTree();
		
		BudgetNode bnl1_1 = bmc.budgetNodesMap.get(bnl1_1GenId);
		System.assertNotEquals(null, bnl1);
		System.assertNotEquals(null, bnl1_1.objId);
				
		bmc.saveTree();

		// Retrieves Budget Owner, Program Budget, and Budget Line from the database
		Budgets__c bl1 = [select Id, Name, Period__c, Budget_Owner__c from Budgets__c where Id =: bnl1.objId];
		// Same as bl1 but different Name and Period
		Budgets__c bl1_1 = [select Id, Name, Period__c, Budget_Owner__c from Budgets__c where Id =: bnl1_1.objId];
		Program_Budget__c bl2 = [select Id, Name, Budget_Owner__c from Program_Budget__c where Id =: bnl2.objId];
		Budget_Line__c bl3 = [select Id, Name, Program_Budget__c from Budget_Line__c where Id =: bnl3.objId];
		System.assertEquals(bnl1.objId, bl1.Id);
		System.assertEquals(bnl1_1.objId, bl1_1.Id);
		// bl1 is equal to bl1_1 except for the Name and Period
		System.assertNotEquals(bl1.Name, bl1_1.Name);
		System.assertNotEquals(bl1.Period__c, bl1_1.Period__c);
		System.assertEquals(bl1.Budget_Owner__c, bl1_1.Budget_Owner__c);
		
		System.assertEquals(bnl2.objId, bl2.Id);
		System.assertEquals(bnl3.objId, bl3.Id);
		// Test that the Budget Owner Name was generated automatically (workflow)
		System.assertEquals(bmc.periodsList.get(0).getLabel() + ' ' + bmc.level1BudgetArea, bl1.Name);
		// Test that the Program Budget Name was generated automatically (workflow) 
		System.assertEquals(bl1.Name + ': ' + bmc.level3BudgetPlanBudget + (bmc.level3BudgetShortName == '' ? '' : ': ' + bmc.level3BudgetShortName), bl2.Name);
		// Test proper association between bl1, bl2, bl3
		System.assertEquals(bl1.Id, bl2.Budget_Owner__c);
		System.assertEquals(bl2.Id, bl3.Program_Budget__c);
		
		// update bl3 to trigger recurring process
		bl3.Recurring__c = true;
		bl3.Number_of_Quarters__c = 4;
		bl3.Recurring_Start_Period__c = bmc.periodsList.get(1).getValue();
		test.startTest();
		update bl3;
		test.stopTest();
		
		// Test that the tree was also created for the following (level4BudgetNumberOfQuarters) quarters, starting at (level4BudgetRecurringStartPeriod)
		// But it didn't recreate the Budget Owner for the starting period since the Budget Owner already exists for that period
		    	
    	Period__c recurringStartPeriod = [select Id, Name, Start_Date__c, End_Date__c, Type__c, Number__c, ParentPeriod__c, ParentPeriod__r.Id, ParentPeriod__r.Name, ParentPeriod__r.Start_Date__c, ParentPeriod__r.End_Date__c, ParentPeriod__r.Type__c, ParentPeriod__r.Number__c from Period__c where Id =: bl3.Recurring_Start_Period__c limit 1][0];
    	
		// We need the periods on which we are going to test if the tree was created
		List<Period__c> periods = bpu.getRecurringPeriods(recurringStartPeriod, Math.round(bl3.Number_of_Quarters__c));
		
		for (Period__c p : periods) {
			List<Budgets__c> bl1ByPeriod;
			// Since the Budget Owner exists for current period, it should've not created a new one
			if (p.Id == bmc.periodsList.get(1).getValue()) { 
				// Test that the Budget Owner was not copied
	    		String auxBOwnerName = bl1.Name;
				String bOwnerName = auxBOwnerName.replace(auxBOwnerName.substring(0,6), p.Name);
				
				bl1ByPeriod = [select Id, Name from Budgets__c where Name =: bOwnerName and Period__c =: p.Id];
				System.assertEquals(1, bl1ByPeriod.size()); // If it succeds means that no new Budget Owner was created.			
			} else {
				// Test that the Budget Owner was copied
	    		String auxBOwnerName = bl1.Name;
				String bOwnerName = auxBOwnerName.replace(auxBOwnerName.substring(0,6), p.Name);
				bl1ByPeriod = [select Id, Name from Budgets__c where Name =: bOwnerName and Period__c =: p.Id];
				System.assertNotEquals(null, bl1ByPeriod.get(0).Id);						
			}
			// Test that the Program Budget was copied
			Program_Budget__c bl2ByPeriod = [select Id, Name from Program_Budget__c where Budget_Owner__c =: bl1ByPeriod.get(0).Id];
			System.assertNotEquals(null, bl2ByPeriod.Id);
			// Test that the Budget Line was copied
			Budget_Line__c bl3ByPeriod = [select Id, Name from Budget_Line__c where Program_Budget__c =: bl2ByPeriod.Id];
			System.assertNotEquals(null, bl3ByPeriod.Id);
		}				 		
	}
	
	
	
	static testMethod void testRecurringBudgetOwnerAndProgramBudgetExist() {
		loadCustomSetting();
		createPeriods();

		// I set BudgetRecurringUtility.isTest to true, to let know we are in a test context
		BudgetRecurringUtility.isTest = true;
		
		BudgetManagerController bmc = new BudgetManagerController();
		
		BudgetPeriodUtility bpu = new BudgetPeriodUtility();

		List<BudgetNode> nodes = createTreeForTest(bmc);
		BudgetNode bnl1 = nodes.get(0);
		BudgetNode bnl2 = nodes.get(1);
		BudgetNode bnl3 = nodes.get(2);
		
		// We create a Budget Owner and a Program Budget for a different period (bmc.periodsList.get(1).getValue()) and we copy the values from the Budget Owner previously created (bnl1) 
		Integer bnl1_1GenId = bmc.i; // Id generated automatically when we add a node
		bmc.parentNode = '';
		bmc.level1BudgetPeriod = bmc.periodsList.get(1).getValue();
		bmc.level1BudgetArea = 'DiegoFeblesTest';
		bmc.addNode();
		
		Integer bnl2_1GenId = bmc.i; // Id generated automatically when we add a node
		bmc.parentNode = bnl1_1GenId.format(); // Assign this Program Budget to the Budget Owner previously created
		bmc.level3BudgetOwner = 'Owner Test 2';
		bmc.level3BudgetPlanBudget = bmc.planBudgetCodesList.get(0).getValue();
		bmc.addNode();

		bmc.saveTree();
				
		BudgetNode bnl1_1 = bmc.budgetNodesMap.get(bnl1_1GenId);
		System.assertNotEquals(null, bnl1);
		System.assertNotEquals(null, bnl1_1.objId);	

		BudgetNode bnl2_1 = bmc.budgetNodesMap.get(bnl2_1GenId);
		System.assertNotEquals(null, bnl2_1);
		System.assertNotEquals(null, bnl2_1.objId);
		// Check that the Program Budget was assigned to Budget Owner
		System.assertEquals(bnl1_1.objId, ((ProgramBudget)bnl2_1).obj.Budget_Owner__c);
				
		bmc.saveTree();
		
		// Retrieve Budget Owner, Program Budget, and Budget Line from database
		Budgets__c bl1 = [select Id, Name, Period__c, Budget_Owner__c from Budgets__c where Id =: bnl1.objId];
		// Same as bl1 but different Name and Period
		Budgets__c bl1_1 = [select Id, Name, Period__c, Budget_Owner__c from Budgets__c where Id =: bnl1_1.objId];
		Program_Budget__c bl2 = [select Id, Name, Budget_Owner__c from Program_Budget__c where Id =: bnl2.objId];
		Budget_Line__c bl3 = [select Id, Name, Program_Budget__c from Budget_Line__c where Id =: bnl3.objId];
		System.assertEquals(bnl1.objId, bl1.Id);
		System.assertEquals(bnl1_1.objId, bl1_1.Id);
		// bl1 is equal to bl1_1 except for Name and Period
		System.assertNotEquals(bl1.Name, bl1_1.Name);
		System.assertNotEquals(bl1.Period__c, bl1_1.Period__c);
		System.assertEquals(bl1.Budget_Owner__c, bl1_1.Budget_Owner__c);
		
		System.assertEquals(bnl2.objId, bl2.Id);
		System.assertEquals(bnl3.objId, bl3.Id);
		// Verify that the Budget Owner Name was generated automatically (workflow)
		System.assertEquals(bmc.periodsList.get(0).getLabel() + ' ' + bmc.level1BudgetArea, bl1.Name);
		// Verify that the Program Budget Name was generated automatically (workflow) 
		System.assertEquals(bl1.Name + ': ' + bmc.level3BudgetPlanBudget + (bmc.level3BudgetShortName == '' ? '' : ': ' + bmc.level3BudgetShortName), bl2.Name);
		// Verify proper association between bl1, bl2, bl3
		System.assertEquals(bl1.Id, bl2.Budget_Owner__c);
		System.assertEquals(bl2.Id, bl3.Program_Budget__c);
		
		// update bl3_recurring to trigger recurring process
		bl3.Recurring__c = true;
		bl3.Number_of_Quarters__c = 4;
		bl3.Recurring_Start_Period__c = bmc.periodsList.get(1).getValue();
		test.startTest();		
		update bl3;
		test.stopTest();
		
		// Test that the tree was also created for the following (level4BudgetNumberOfQuarters) quarters, starting at (level4BudgetRecurringStartPeriod)
		// But it didn't recreate the Budget Owner for the starting period since the Budget Owner already exists for that period
		
		Period__c recurringStartPeriod = [select Id, Name, Start_Date__c, End_Date__c, Type__c, Number__c, ParentPeriod__c, ParentPeriod__r.Id, ParentPeriod__r.Name, ParentPeriod__r.Start_Date__c, ParentPeriod__r.End_Date__c, ParentPeriod__r.Type__c, ParentPeriod__r.Number__c from Period__c where Id =: bl3.Recurring_Start_Period__c limit 1][0];
		
		// We need the periods on which we are going to test if the tree was created
		List<Period__c> periods = bpu.getRecurringPeriods(recurringStartPeriod, Math.round(bl3.Number_of_Quarters__c));
		
		for (Period__c p : periods) {
			List<Budgets__c> bl1ByPeriod;
			List<Program_Budget__c> bl2ByPeriod;
			// Since the Budget Owner exists already for this period, it should've not created a new one
			if (p.Id == bmc.periodsList.get(1).getValue()) { 
				// Test that the Budget Owner and Program Budget were not copied since they already exist
	    		String auxBOwnerName = bl1.Name;
				String bOwnerName = auxBOwnerName.replace(auxBOwnerName.substring(0,6), p.Name);
				
				bl1ByPeriod = [select Id, Name from Budgets__c where Name =: bOwnerName and Period__c =: p.Id];
				System.assertEquals(1, bl1ByPeriod.size()); // If it succeds means that no new Budget Owner was created.

				// Test that the Program Budget was not copied
				bl2ByPeriod = [select Id, Name from Program_Budget__c where Budget_Owner__c =: bl1ByPeriod.get(0).Id];
				System.assertEquals(1, bl2ByPeriod.size()); // If it succeds means that no new Program Budget was created.							
			} else {
				// Test that the Budget Owner was copied
	    		String auxBOwnerName = bl1.Name;
				String bOwnerName = auxBOwnerName.replace(auxBOwnerName.substring(0,6), p.Name);
				bl1ByPeriod = [select Id, Name from Budgets__c where Name =: bOwnerName and Period__c =: p.Id];
				System.assertNotEquals(null, bl1ByPeriod.get(0).Id);						

				// Test that the Program Budget was copied
				bl2ByPeriod = [select Id, Name from Program_Budget__c where Budget_Owner__c =: bl1ByPeriod.get(0).Id];
				System.assertNotEquals(null, bl2ByPeriod.get(0).Id);
			}
			// Test that the Budget Line was copied
			Budget_Line__c bl3ByPeriod = [select Id, Name from Budget_Line__c where Program_Budget__c =: bl2ByPeriod.get(0).Id];
			System.assertNotEquals(null, bl3ByPeriod.Id);
		}				 			
	}
	
		
	static testMethod void testManageBudgetButtonForBudgets() {
		createPeriods();
		
		List<SObject> l = createData();
		List<Budgets> boList = new List<Budgets>();
		List<ProgramBudget> pbList = new List<ProgramBudget>();
		List<BudgetLine> blList = new List<BudgetLine>();
		
		Budgets__c budgetOwner = (Budgets__c) l.get(1);
		
		// Set page parameters - Simulate that we clicked the Manage Button in the Budgets layout
		ApexPages.currentPage().getParameters().put('bid', budgetOwner.Id);
		ApexPages.currentPage().getParameters().put('level', 'budgetOwner');
		
		BudgetManagerController bmc = new BudgetManagerController();
		
		// If I clicked on 'Manage Budgets' readOnly should be false
		System.assertEquals(false, bmc.readOnly);
		
		for (BudgetNode a : bmc.tree.children) {
			boList.add((Budgets)a);
			for (BudgetNode b : a.children) {
				pbList.add((ProgramBudget)b);
				for (BudgetNode c : b.children) {
					blList.add((BudgetLine)c);
				}
			}
		}
		System.assertEquals(1, boList.size());
		System.assertEquals(1, pbList.size());
		System.assertEquals(1, blList.size());

		// Retrieve Budgets's child
		Program_Budget__c pb = [select Id from Program_Budget__c where Budget_Owner__c =: budgetOwner.Id];
		System.assertNotEquals(null, pb.Id);
		
		// Retrieve pb's child
		Budget_Line__c bl = [select Id from Budget_Line__c where Program_Budget__c =: pb.Id];
		System.assertNotEquals(null, bl.Id);
				
		System.assertEquals(budgetOwner.Id, boList.get(0).obj.Id);
		System.assertEquals(pb.Id, pbList.get(0).obj.Id);
		System.assertEquals(bl.Id, blList.get(0).obj.Id); 
	}

	static testMethod void testManageBudgetButtonForProgramBudget() {
		createPeriods();
		
		List<SObject> l = createData();
		List<Budgets> boList = new List<Budgets>();
		List<ProgramBudget> pbList = new List<ProgramBudget>();
		List<BudgetLine> blList = new List<BudgetLine>();
		
		Program_Budget__c programBudget = (Program_Budget__c) l.get(2);
		
		// Set page parameters - Simulate that we clicked the Manage Button in the Program Budget layout
		ApexPages.currentPage().getParameters().put('bid', programBudget.Id);
		ApexPages.currentPage().getParameters().put('level', 'programBudget');
		
		BudgetManagerController bmc = new BudgetManagerController();

		// If I clicked on 'Manage Budgets' readOnly should be false
		System.assertEquals(false, bmc.readOnly);
		
		for (BudgetNode a : bmc.tree.children) {
			boList.add((Budgets)a);
			for (BudgetNode b : a.children) {
				pbList.add((ProgramBudget)b);
				for (BudgetNode c : b.children) {
					blList.add((BudgetLine)c);
				}
			}
		}
		System.assertEquals(1, boList.size());
		System.assertEquals(1, pbList.size());
		System.assertEquals(1, blList.size());

		// Retrieve programBudget's parent
		Budgets__c bo = [select Id from Budgets__c where Id =: programBudget.Budget_Owner__c];
		System.assertNotEquals(null, bo.Id);
		
		// Retrieve programBudget's child
		Budget_Line__c bl = [select Id from Budget_Line__c where Program_Budget__c =: programBudget.Id];
		System.assertNotEquals(null, bl.Id);

		System.assertEquals(bo.Id, boList.get(0).obj.Id);
		System.assertEquals(programBudget.Id, pbList.get(0).obj.Id);
		System.assertEquals(bl.Id, blList.get(0).obj.Id);
	}

	static testMethod void testManageBudgetButtonForBudgetLine() {
		createPeriods();
		
		List<SObject> l = createData();
		List<Budgets> boList = new List<Budgets>();
		List<ProgramBudget> pbList = new List<ProgramBudget>();
		List<BudgetLine> blList = new List<BudgetLine>();
		
		Budget_Line__c budgetLine = (Budget_Line__c) l.get(3);
		
		// Set page parameters - Simulate that we clicked the Manage Button in the Budget Line layout
		ApexPages.currentPage().getParameters().put('bid', budgetLine.Id);
		ApexPages.currentPage().getParameters().put('level', 'budgetLine');
		
		BudgetManagerController bmc = new BudgetManagerController();

		// If I clicked on 'Manage Budgets' readOnly should be false
		System.assertEquals(false, bmc.readOnly);		

		for (BudgetNode a : bmc.tree.children) {
			boList.add((Budgets)a);
			for (BudgetNode b : a.children) {
				pbList.add((ProgramBudget)b);
				for (BudgetNode c : b.children) {
					blList.add((BudgetLine)c);
				}
			}
		}
		System.assertEquals(1, boList.size());
		System.assertEquals(1, pbList.size());
		System.assertEquals(1, blList.size());
		
		// Retrieve budgetLine's parent
		Program_Budget__c pb = [select Id, Budget_Owner__c from Program_Budget__c where Id =: budgetLine.Program_Budget__c];
		System.assertNotEquals(null, pb.Id);
		System.assertNotEquals(null, pb.Budget_Owner__c);
		
		// Retrieve pb's parent
		Budgets__c bo = [select Id from Budgets__c where Id =: pb.Budget_Owner__c];
		System.assertNotEquals(null, bo.Id);
		
		System.assertEquals(bo.Id, boList.get(0).obj.Id);
		System.assertEquals(pb.Id, pbList.get(0).obj.Id);
		System.assertEquals(budgetLine.Id, blList.get(0).obj.Id);
	}

	static testMethod void testManageBudgetButtonForPurchaseRequest() {
		createPeriods();
		
		List<SObject> l = createData();
		List<Budgets> boList = new List<Budgets>();
		List<ProgramBudget> pbList = new List<ProgramBudget>();
		List<BudgetLine> blList = new List<BudgetLine>();
		List<PurchaseRequest> prList = new List<PurchaseRequest>();
		
		Purchase_Request__c purchaseRequest = (Purchase_Request__c) l.get(4);
		
		// Set page parameters - Simulate that we clicked the Manage Button in the Budget Line layout
		ApexPages.currentPage().getParameters().put('bid', purchaseRequest.Id);
		ApexPages.currentPage().getParameters().put('level', 'purchaseRequest');
		
		BudgetManagerController bmc = new BudgetManagerController();

		// If I clicked on 'Manage Budgets' readOnly should be false
		System.assertEquals(false, bmc.readOnly);
		
		for (BudgetNode a : bmc.tree.children) {
			boList.add((Budgets)a);
			for (BudgetNode b : a.children) {
				pbList.add((ProgramBudget)b);
				for (BudgetNode c : b.children) {
					blList.add((BudgetLine)c);
					for (BudgetNode d : c.children) {
						prList.add((PurchaseRequest)d);
					}
				}
			}
		}
		System.assertEquals(1, boList.size());
		System.assertEquals(1, pbList.size());
		System.assertEquals(1, blList.size());
		System.assertEquals(1, prList.size());
		
		// Retrieve purchaseRequest's parent
		Budget_Line__c bl = [select Id, Program_Budget__c from Budget_Line__c where Id =: purchaseRequest.Budget_Line__c];
		System.assertNotEquals(null, bl.Id);
		System.assertNotEquals(null, bl.Program_Budget__c);
		
		// Retrieve bl's parent
		Program_Budget__c pb = [select Id, Budget_Owner__c from Program_Budget__c where Id =: bl.Program_Budget__c];
		System.assertNotEquals(null, pb.Id);
		System.assertNotEquals(null, pb.Budget_Owner__c);
		
		// Retrieve pb's parent
		Budgets__c bo = [select Id from Budgets__c where Id =: pb.Budget_Owner__c];
		System.assertNotEquals(null, bo.Id);
		
		System.assertEquals(bo.Id, boList.get(0).obj.Id);
		System.assertEquals(pb.Id, pbList.get(0).obj.Id);
		System.assertEquals(bl.Id, blList.get(0).obj.Id);
		System.assertEquals(purchaseRequest.Id, prList.get(0).obj.Id);
	}
	
	static testMethod void testErrors() {
		createPeriods();
		
		// Invoking add node when I don't have a parent
		BudgetManagerController bmc = new BudgetManagerController();
		bmc.parentNode = 'test';
		bmc.addNode();
		System.assertEquals('Invalid integer.', bmc.errorMsg);
	}
   	
	static testMethod void testloadAllListsNoneOption() {
		createPeriods();
		
		BudgetManagerController bmc = new BudgetManagerController();
		SelectOption so;
		
		so = bmc.regionsList[0];
		System.assertEquals(so.getLabel(),'-None-');
		System.assertEquals(so.getValue(),'');

		so = bmc.departmentsList[0];
		System.assertEquals(so.getLabel(),'-None-');
		System.assertEquals(so.getValue(),'');

		so = bmc.planBudgetCodesList[0];
		System.assertEquals(so.getLabel(),'-None-');
		System.assertEquals(so.getValue(),'');

		so = bmc.pbBudgetOwnersList[0];
		System.assertEquals(so.getLabel(),'-None-');
		System.assertEquals(so.getValue(),'');

	} 

	static testMethod void testBudgetNodes(){
		
		BudgetNode bn = new BudgetNode(1);
		bn.name = bn.name;
		bn.approved = bn.approved; 
		bn.requested = bn.requested;
		bn.approvedTotal = bn.approvedTotal;
		bn.requestedS = bn.requestedS;
		bn.approvedS = bn.approvedS;
		bn.remainingS = bn.remainingS;
		bn.approvedTotalS = bn.approvedTotalS; 
		Decimal d = bn.BLApprovedUncommitted;
		String s = bn.BLApprovedUncommittedS;
		Id o = bn.objId;
		s = bn.Region;
		Integer i = bn.Level;
		Boolean b = bn.isNew;
		bn.resetAmounts();
		
		System.assertEquals(bn.approved, bn.savedApproved);
	}
	
	static testMethod void testBudgetLine(){
		BudgetLine bl = new BudgetLine(1,new Budget_Line__c(Budget_Line_Amount__c = 3));
		bl.name = bl.name;
		Integer i = bl.level;
		bl.approved = bl.approved; 
		bl.requested = bl.requested;
		Decimal d = bl.BLApprovedUncommitted;
		Id o = bl.objId;
		
		System.assertEquals(i, bl.level);
	}
	
	
    public static testMethod void testBUtil(){
    	
    	BudgetUtil.formatDecimal(null);
    	BudgetUtil.formatDecimal(Decimal.valueOf(3));
    	BudgetUtil.parseDecimal('3');
    	
    	System.assertEquals(3, BudgetUtil.parseDecimal('3'));
    }
}