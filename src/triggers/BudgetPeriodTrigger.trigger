trigger BudgetPeriodTrigger on Period__c (before insert, before update) {

	BudgetPeriodUtility ctl = new BudgetPeriodUtility();	
	Set<Id> parentIds = new Set<Id>();
	for(Period__c p: trigger.new){
		parentIds.add(p.parentPeriod__c);
	}
	Map<Id,Period__c> periodsMap = new Map<Id,Period__c>([Select id, Number__c, Type__c, Start_Date__c from Period__c where id in :parentIds]);
	for(Period__c p: trigger.new){
		p.parentPeriod__r = periodsMap.get(p.parentPeriod__c);
		p.Name = ctl.calculateName(p);
	}
}