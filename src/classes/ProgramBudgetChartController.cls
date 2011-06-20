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

/* This class provides the necessary data to create a chart for the Program_Budget__c
 *
 * @since 2010-05
 */
public with sharing class ProgramBudgetChartController {
	public Program_Budget__c programBudget {get;set;}
	public Decimal spendings {get;set;}
	public Decimal savings {get;set;}
	
	/*
	 * Calculates spendings and savings for a program budget
	 * @param stdController that then is cast to Program_Budget__c
	 */	
	public ProgramBudgetChartController(ApexPages.StandardController stdController) {
		programBudget = (Program_Budget__c) stdController.getRecord();
		List<Program_Budget__c> l = new List<Program_Budget__c> ([select Program_Budget_Amount__c, Unallocated_Budget_Line_Amount__c from Program_Budget__c where Id =: programBudget.Id]);
		if (l.size() > 0) {
			if ((l.get(0).Program_Budget_Amount__c != null) && (l.get(0).Unallocated_Budget_Line_Amount__c != null)) {
				// spendings are calculated based on Program_Budget_Amount(amount to spend) - Unallocated (amount to spend left)
				spendings = l.get(0).Program_Budget_Amount__c - l.get(0).Unallocated_Budget_Line_Amount__c;
				// the savings are what we have Unallocated
				savings = l.get(0).Unallocated_Budget_Line_Amount__c;
			} else {
				spendings = 0;
				savings = 0;
			}
		}
	}
}