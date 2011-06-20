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

/* This class provides some utility methods for Budgets.
 * @since 2010-05
 */

public with sharing class BudgetUtil {
	
	public static String nbrSeparator{get;set;}
    public static String nbrDecimal{get;set;}
    public static String errorMsg {get;set;}
    
    public static void determineNumberFormat(){        
        Decimal nbr = 1234.56;
        String n = nbr.format();               
        BudgetUtil.nbrSeparator = n.substring(1,2);
        BudgetUtil.nbrDecimal = n.substring(5,6);
        
    }

    public static String formatDecimal(Decimal d) {
        
        if(d == null){
        	return '0';
        }
                
        if(BudgetUtil.nbrSeparator == null || BudgetUtil.nbrDecimal == null){
            determineNumberFormat();
        }
        d = d.setScale(2);
        String s = d.toPlainString();
        String[] ss = s.split('\\.');
        if (ss.size() == 2) {
            return Decimal.valueOf(ss[0]).format() + BudgetUtil.nbrDecimal + ss[1];
        } else {
            //should not happen
            return d.format();
        }
    }
    
    public static Decimal parseDecimal(String value){
                
        if(value==null || value=='')
           return 0;
        
        if(BudgetUtil.nbrSeparator == null || BudgetUtil.nbrDecimal == null){
            determineNumberFormat();
        }
        value = value.replace( BudgetUtil.nbrSeparator, '');
        if(BudgetUtil.nbrDecimal != '.'){
            value = value.replace( BudgetUtil.nbrDecimal, '.');
        }
        return Decimal.valueOf(value);
    }  

    /*
     * Method: save()
     * Saves the tree to the database
     */
	public static String save(BudgetNode tree) {
		List<Budgets__c> level1 = new List<Budgets__c>();
		List<Program_Budget__c> level3 = new List<Program_Budget__c>();
		List<Budget_Line__c> level4 = new List<Budget_Line__c>();
		
		errorMsg = ''; // Initialize errorMsg
		
		for (BudgetNode a : tree.children) {
			level1.add(((Budgets)a).obj);
		} 
		Database.upsertResult[] resultsLevel1 = Database.upsert(level1, false);
		processResults(resultsLevel1);
		
		for (BudgetNode a : tree.children) {
			for (BudgetNode b : a.children) {
				Program_Budget__c bObj = ((ProgramBudget)b).obj;
				level3.add(bObj);
				if (bObj.Budget_Owner__c == null)
					bObj.Budget_Owner__c = a.objId;
			}
		}
		Database.UpsertResult[] resultsLevel3 = Database.upsert(level3, false);
		processResults(resultsLevel3);
		
		for (BudgetNode a : tree.children) {
			for (BudgetNode b : a.children) {
				for (BudgetNode c : b.children) {
					Budget_Line__c cObj = ((BudgetLine)c).obj; 
					level4.add(cObj);
					if (cObj.Program_Budget__c == null)
						cObj.Program_Budget__c = b.objId;
				}
			}
		}
		Database.UpsertResult[] resultsLevel4 = Database.upsert(level4, false);   
		processResults(resultsLevel4);	 
		tree.resetAmounts();
		return errorMsg;
	}
	
    /* Utility method to iterate UpsertResult array and add any errors to the errorMsg variable
     *
     * @param result a UpsertResult array to process
     */    
    private static void processResults(Database.UpsertResult[] results) {
 		// If there are some results, proceed...
        if (results != null) {

            for (Database.UpsertResult result : results) {
                if (!result.success) {
                    if (result.getErrors() != null) {
                    	for (Database.Error error : result.getErrors()) {
                            errorMsg += error.getMessage();
                            errorMsg += '<br/>';
                    	}
                    }
                    else {
                        errorMsg += 'Error saving, but there was no error message\n';
                    }
                }
            }
        }  
    }
}