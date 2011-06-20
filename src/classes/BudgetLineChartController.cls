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

/* This class provides the necessary data to create two charts for the Budget_Line__c
 *
 * @since 2010-05
 */
public with sharing class BudgetLineChartController {
	public Budget_Line__c budgetLine {get;set;}
	public List<Purchase_Request__c> purchaseRequests {get; set;}
	public Decimal spendings {get;set;}
	public Decimal savings {get;set;}
	
	{ // initialize instance variables
		budgetLine = new Budget_Line__c();
		purchaseRequests = new List<Purchase_Request__c>();
		spendings = 0;
		savings = 0;
	}
	
   /*
	* Constructor
	* @param stdController that then is cast to Budget_Line__c
	*/
	public BudgetLineChartController(ApexPages.StandardController stdController) {
		budgetLine = (Budget_Line__c) stdController.getRecord();
		initChartValues();
	}

	/*
	 * Calculates spendings and savings
	 * Calculates the distribution of purchase requests
	 */	
	private void initChartValues() {
		List<Budget_Line__c> l = new List<Budget_Line__c> ([select Budget_Line_Amount__c, 
																   Uncommitted_Approved_Budget__c,
																   (select Name, Purchase_Request_Amount__c from Purchase_Requests1__r where Purchase_Request_Amount__c != null order by Purchase_Request_Amount__c desc) 
														    from Budget_Line__c where Id =: budgetLine.Id limit 1]);

		if (l.size() > 0 && l.get(0).Budget_Line_Amount__c != null && l.get(0).Uncommitted_Approved_Budget__c != null) {
			Budget_Line__c b = l.get(0);
			// spendings are calculated based on Budget_Line_Amount(amount to spend) - Uncommited (amount to spend left)
			spendings = b.Budget_Line_Amount__c - b.Uncommitted_Approved_Budget__c;
			// the savings are what we have Uncommited
			savings = b.Uncommitted_Approved_Budget__c;
			// Distribution of Purchase Requests
			if (b.Purchase_Requests1__r.size() > 0) {
				purchaseRequests = b.Purchase_Requests1__r;
			}
		} 
	}
}