trigger BudgetLineTrigger on Budget_Line__c (after insert, after update) {
	
	if (trigger.isInsert) {
		BudgetRecurringUtility.processRecurringBudget(trigger.new, null);
	
	}
	
	if (trigger.isUpdate) {
		BudgetRecurringUtility.processRecurringBudget(trigger.new, trigger.old);
		
	}
}