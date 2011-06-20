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

/*
 * Utility class to manipulate period objects.
 */
public without sharing class BudgetPeriodUtility {
	
	//Dates for the Salesforce.com fiscal year
	public Date FYStart;
	public Date FYEnd;
	public List<Date> qStart;
	public List<Date> qEnd;
	
	/*
	 * Constructor
	 */
	public BudgetPeriodUtility(){
        // validates the ReclaimBudgetCS custom setting 
    	ReclaimBudgetCS__c setting = ReclaimBudgetCS__c.getInstance();
    	
    	if (!validateReclaimBudgetCSSetting(setting)) {
    		System.debug('ReclaimBudgetCS custom setting is not defined');
    		return;
    	}
 
		FYStart = setting.FYStart__c;
		FYEnd = setting.FYEnd__c;
		qStart = new List<Date>{setting.Q1Start__c,setting.Q2Start__c,setting.Q3Start__c,setting.Q4Start__c};
		qEnd = new List<Date>{setting.Q1End__c,setting.Q2End__c,setting.Q3End__c,setting.Q4End__c};
	}
		
	/*
	 * Return quarters in ascending order.
	 */
	public List<Period__c> getQuarters(){
		return getQuarters(true);
	}
	
	/*
	 * Return the quarters in ascending or descending order depending on the variable.
	 */
	public List<Period__c> getQuarters(Boolean ascending){
		
		String order = ascending ? 'asc' : 'desc';
		String query = 'Select Id, Name, Start_Date__c, End_Date__c, Type__c, Number__c, ParentPeriod__c, ParentPeriod__r.Id, ParentPeriod__r.Name, ParentPeriod__r.Start_Date__c, ParentPeriod__r.End_Date__c, ParentPeriod__r.Type__c, ParentPeriod__r.Number__c from Period__c where Type__c = \'Quarter\' order by ParentPeriod__r.Number__c '+order+', Number__c '+order;
		return new List<Period__c>((List<Period__c>)Database.query(query));
	}
	
	/*
	 * Generate the name of a given period
	 */
	public String calculateName(Period__c p){
		
		if(p.Type__c == 'Year'){
			return String.valueOf(Math.round(p.Number__c));
		}
		else if(p.Type__c == 'Quarter'){
			return 'FY'+calculateName(p.ParentPeriod__r).substring(2)+'Q'+Math.round(p.Number__c);
		}
		else if(p.Type__c == 'Month'){
			return DateTime.newInstance(p.Start_Date__c.year(),p.Start_Date__c.month(),p.Start_Date__c.day()).format('MMMMM');
		}
		else{
			return '';
		}
	}
	/*
	 * Return a list of selectoption to display in the UI of the quarters
	 */
	public List<SelectOption> getQuarterOptions(){
		List<SelectOption> options = new List<SelectOption>();
		for(Period__c p: getQuarters(false)){
			options.add(new SelectOption(p.Id, calculateName(p)));
		}
		return options;
	}
	
	/*
	 * Change the year of a given date
	 */
	public Date changeYear(Date d, Integer year){
		return Date.newInstance(year,d.month(),d.day());
	}
	
	/*
	 * Method to fill in missing quarters given a starting period and a number of quarters it will repeat including the start period.
	 */ 
	public List<Period__c> getRecurringPeriods(Period__c startPeriod, Integer numberOfQuarters){
		
		if(startPeriod.type__c != 'Quarter' || numberOfQuarters < 1){
			return new List<Period__c>();
		}
		
		//Gather quarters beyond start period (inclusive)
		Map<String,Period__c> quarters = new Map<String,Period__c>();
		for(Period__c p: [Select Id, Name, Start_Date__c, End_Date__c, Type__c, Number__c, ParentPeriod__c, ParentPeriod__r.Id, ParentPeriod__r.Name, ParentPeriod__r.Start_Date__c, ParentPeriod__r.End_Date__c, ParentPeriod__r.Type__c, ParentPeriod__r.Number__c from Period__c where Type__c = 'Quarter' and Start_Date__c >= :startPeriod.Start_Date__c order by ParentPeriod__r.Number__c asc, Number__c asc limit :numberOfQuarters]){
			quarters.put(p.Number__c+'-'+p.ParentPeriod__r.Number__c,p);
		}
		
		//Gather all years
		Map<Integer, Period__c> years = new Map<Integer, Period__c>();
		for(Period__c bp: [Select Id, Name, Start_Date__c, End_Date__c, Type__c, Number__c, ParentPeriod__c, ParentPeriod__r.Id, ParentPeriod__r.Name, ParentPeriod__r.Start_Date__c, ParentPeriod__r.End_Date__c, ParentPeriod__r.Type__c, ParentPeriod__r.Number__c from Period__c where Type__c = 'Year' and Start_Date__c >= :startPeriod.parentPeriod__r.Start_Date__c order by Number__c asc]){
			years.put(Math.round(bp.Number__c), bp);
		}
		
		List<Period__c> yearsToInsert = new List<Period__c>();
		List<Period__c> quartersToInsert = new List<Period__c>();
		List<Period__c> quartersList = new List<Period__c>();
    	Integer quarterCounter = Math.round(startPeriod.Number__c); //This is te current quarter number for the iteration
    	Integer yearCounter = Math.round(startPeriod.parentPeriod__r.Number__c); //This is the current year number for the iteration
    	Period__c currentYear; //This is the current year for the iteration
    	Period__c currentQuarter; //This is te current quarter for the iteration
    	/*
    	 * The following are increments for the year of the quarter needs respect the FYStart year. Here is an example:
    	 * FYStart = 5/1/2010, then FYEnd = 4/30/2011, inc = 1. 
		 * FYStart = 1/1/2010, then FYEnd = 12/31/2010, inc = 0.
		 */
    	Integer startIncrement; 
		Integer endIncrement;
    		
    	for (Integer j = 0; j < numberOfQuarters; j++) {
    		
    		//If not exists, create it, else get it from map
    		if(!years.containsKey(yearCounter)){
				endIncrement = (FYEnd.year()-FYStart.year());
    			currentYear = new Period__c(Start_Date__c = changeYear(FYStart,yearCounter), End_Date__c = changeYear(FYEnd,yearCounter+endIncrement), Number__c = yearCounter, Type__c='Year');
    			currentYear.Name = calculateName(currentYear);
    			years.put(yearCounter,currentYear);
    			yearsToInsert.add(currentYear);
    		}
    		else{
    			currentYear = years.get(yearCounter);
    		}
    		
    		//If not exists, create it, else get it from map
    		if(!quarters.containsKey(quarterCounter+'-'+yearCounter) && 
    		   qStart != null && qStart.size() > 0 && qEnd != null && qEnd.size() > 0){
    			
    			startIncrement = qStart.get(quarterCounter-1).year()-FYStart.year();
    			endIncrement =   qEnd.get(quarterCounter-1).year()-FYStart.year();
    			
    			Date startDate = changeYear(qStart.get(quarterCounter-1),yearCounter+startIncrement);
    			Date endDate = changeYear(qEnd.get(quarterCounter-1),yearCounter+endIncrement);
    			
    			currentQuarter = new Period__c(Start_Date__c = startDate, End_Date__c = endDate, parentPeriod__r = currentYear, Number__c = quarterCounter, Type__c='Quarter');
    			currentQuarter.Name = calculateName(currentQuarter);
    			quartersToInsert.add(currentQuarter);
    		}
    		else{
    			currentQuarter = quarters.get(quarterCounter+'-'+yearCounter);
    		}
			
			//Add to list
			quartersList.add(currentQuarter);
			
			//Adjust counters for next interation.
			quarterCounter++;
			if(quarterCounter == 5){
				quarterCounter = 1;
				yearCounter++;
			}
    	}
    	
    	//Insert years
    	insert yearsToInsert;
    	
    	//Reference quarters to years	
    	for(Period__c q: quartersToInsert){
    		q.parentPeriod__c = q.parentPeriod__r.id;
    	}
    	
    	//Insert quarters
    	insert quartersToInsert;
    	
    	//Return collection
    	return quartersList;
	}
	
	public void createPeriodsForCurrentYear(){
		try{
			Integer currentYear = DateTime.now().year();
			
			Integer endIncrement = FYEnd.year()-FYStart.year();
			Period__c currentYearPeriod = new Period__c(Start_Date__c = changeYear(FYStart,currentYear), End_Date__c = changeYear(FYEnd,currentYear+endIncrement), Number__c = currentYear, Type__c='Year');
			currentYearPeriod.Name = calculateName(currentYearPeriod);
			insert currentYearPeriod;
			
			List<Period__c> quartersToInsert = new List<Period__c>();
			System.debug('########## SIZE '+qStart.size());
			for(Integer i = 0; i < qStart.size(); i++){
				
				Integer startYear = currentYear+qStart.get(i).year()-FYStart.year();
    			Integer endYear =   currentYear+qEnd.get(i).year()-FYStart.year();
    			
    			Period__c currentQuarter = new Period__c(Start_Date__c = changeYear(qStart.get(i),startYear), End_Date__c = changeYear(qEnd.get(i),endYear), parentPeriod__r = currentYearPeriod,  parentPeriod__c = currentYearPeriod.id, Number__c = i+1, Type__c='Quarter');
    			currentQuarter.Name = calculateName(currentQuarter);
    			quartersToInsert.add(currentQuarter);
    			System.debug('########## ADDING '+currentQuarter);
			}
			insert quartersToInsert;
		}
		catch(Exception e){
			throw new BudgetException('Periods creation failed: '+e.getMessage());
		}
	}

	/*
	 * Validates the ReclaimBudget_CS custom setting.
	 */
	private static Boolean validateReclaimBudgetCSSetting(ReclaimBudgetCS__c setting) {
		if (setting == null || setting.FYStart__c == null || setting.FYEnd__c == null || setting.Q1Start__c == null ||
			setting.Q2Start__c == null || setting.Q3Start__c == null || setting.Q4Start__c == null || setting.Q1End__c == null ||
			setting.Q2End__c == null || setting.Q3End__c == null || setting.Q4End__c == null
			) {
				notifySettingIsNull('ReclaimBudgetCS');
				return false;
			}
			return true;    	
	} 

	/*
	 * Sends an email notifying that the Custom Setting needs to be defined
	 */
	private static void notifySettingIsNull(String customSettingName) {
        Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
        m.setToAddresses(new String[] {'dfebles@timbasoftware.com'});
        m.setSubject('Please define ' + customSettingName + ' custom setting and its required values.');
        m.setHtmlBody('Please define ' + customSettingName + ' custom setting and its required values in '+UserInfo.getOrganizationName()+' ('+UserInfo.getOrganizationId()+') org.');
        Messaging.sendEmail(new Messaging.Singleemailmessage[]{m});	
	}

	private static void loadCustomSetting() {
		BudgetCustomSettingUtility.loadCustomSettingForTest();
	}
	
	static testMethod void test(){
		loadCustomSetting();
		
		//Call getQuarters with different parameters and assert one is the inverse of the other.
		BudgetPeriodUtility ctl = new BudgetPeriodUtility();
		List<Period__c> ordered = ctl.getQuarters();
		List<Period__c> inverse = ctl.getQuarters(false);
		Integer size = ordered.size();
		
		System.assert(size == inverse.size());
		System.assert(size == ctl.getQuarterOptions().size());
		Boolean different = false; 
		for(Integer i=0; i<size; i++){
			if(ordered.get(i).Number__c != inverse.get(size-i-1).Number__c){
				different = true;
				break;
			}
		}
	
		System.assert(!different);		
		System.assert(ctl.changeYear(Date.newInstance(2010,10,5),2048) == Date.newInstance(2048,10,5));
		Integer year = 2060;
		Period__c yearP = new Period__c(Start_Date__c = ctl.changeYear(ctl.FYStart,year), End_Date__c = ctl.changeYear(ctl.FYEnd,year+ctl.FYEnd.year()-ctl.FYStart.year()), Number__c = year, Type__c='Year');
		Period__c quarter = new Period__c(Type__c = 'Quarter', ParentPeriod__r = yearP, Number__c = 4);
		Period__c month = new Period__c(Type__c = 'Month', ParentPeriod__r = yearP, Start_Date__c=Date.newInstance(2010,1,1));
		
		//Just CC, not asserting names as this may change
		ctl.calculateName(yearP);
		ctl.calculateName(quarter);
		ctl.calculateName(month); 
	}
	
	static testMethod void testRecurring(){
		loadCustomSetting();
				
		Integer year = 2100;
		Integer quarter = 1;
		Integer numberOfQuarters = 8;
		
		List<Period__c> quarters = new List<Period__c>();
		List<Period__c> years = new List<Period__c>();
		BudgetPeriodUtility ctl = new BudgetPeriodUtility();
		
		//Create and insert FY for 2100
		Period__c yearP = new Period__c(Start_Date__c = ctl.changeYear(ctl.FYStart,year), End_Date__c = ctl.changeYear(ctl.FYEnd,year+ctl.FYEnd.year()-ctl.FYStart.year()), Number__c = year, Type__c='Year');
		insert yearP;		
		System.assert(yearP.id != null);	
		
		//Create the first quarter for that year
		Period__c quarter1 = new Period__c(Start_Date__c = ctl.changeYear(ctl.qStart.get(quarter-1),year+(ctl.qStart.get(quarter-1).year()-ctl.FYStart.year())), End_Date__c = ctl.changeYear(ctl.qEnd.get(quarter-1),year+(ctl.qEnd.get(quarter-1).year()-ctl.FYStart.year())), Number__c = quarter, Type__c='Quarter');
		quarter1.ParentPeriod__c = yearP.id;
		
		//Create third quarter for that year
		quarter = 3;
		Period__c quarter3 = new Period__c(Start_Date__c = ctl.changeYear(ctl.qStart.get(quarter-1),year+(ctl.qStart.get(quarter-1).year()-ctl.FYStart.year())), End_Date__c = ctl.changeYear(ctl.qEnd.get(quarter-1),year+(ctl.qEnd.get(quarter-1).year()-ctl.FYStart.year())), Number__c = quarter, Type__c='Quarter');
		quarter3.ParentPeriod__c = yearP.id;
		
		//Insert them
		insert new List<Period__c>{quarter1,quarter3}; 
		System.assert(quarter1.id != null);
		System.assert(quarter3.id != null);
		quarter1.parentPeriod__r = yearP;
		
		//Call recurring periods for the first quarter
		List<Period__c> recs = ctl.getRecurringPeriods(quarter1,numberOfQuarters);
		
		//Assert all the periods were created correctly
		System.assert(recs.size() == numberOfQuarters);
		System.assert(quarter1.id == recs.get(0).id);
		System.assert(quarter3.id == recs.get(2).id,recs);
		Integer inc = 0;
		for(Integer i=0; i<8;i++){
			if(i<4){
				System.assert(recs.get(i).parentPeriod__c == yearP.id);
			}
			else{
				inc = 1;
			}
			System.assert(recs.get(i).Start_Date__c.day() == ctl.qStart.get(Math.mod(i,4)).day());
			System.assert(recs.get(i).Start_Date__c.month() == ctl.qStart.get(Math.mod(i,4)).month());
			System.assert(recs.get(i).Start_Date__c.year() == year+inc+ctl.qStart.get(Math.mod(i,4)).year()-ctl.FYStart.year());
			System.assert(recs.get(i).End_Date__c.day() == ctl.qEnd.get(Math.mod(i,4)).day());
			System.assert(recs.get(i).End_Date__c.month() == ctl.qEnd.get(Math.mod(i,4)).month());		
			System.assert(recs.get(i).End_Date__c.year() == year+inc+ctl.qEnd.get(Math.mod(i,4)).year()-ctl.FYStart.year());	
		}
		
		System.assert(	recs.get(4).ParentPeriod__c == recs.get(5).ParentPeriod__c &&
						recs.get(4).ParentPeriod__c == recs.get(6).ParentPeriod__c &&
						recs.get(4).ParentPeriod__c == recs.get(7).ParentPeriod__c);
						
		Period__c yearP2 = recs.get(4).ParentPeriod__r;
		
		System.assert(yearP2.Start_Date__c == ctl.changeYear(yearP.Start_Date__c,yearP.Start_Date__c.year()+1));
		System.assert(yearP2.End_Date__c == ctl.changeYear(yearP.End_Date__c,yearP.End_Date__c.year()+1));
		System.assert(yearP2.Number__c == yearP.Number__c+1);
	}
	
    static testMethod void testReclaimBudgetCSsetting() {
    	ReclaimBudgetCS__c cs = ReclaimBudgetCS__c.getInstance();
    	if (cs != null) {
    		System.debug('### Found settings - deleting them...');
    		delete [select Id from ReclaimBudgetCS__c];
    		// Check if the setting is null
    		System.assertEquals(false, BudgetPeriodUtility.validateReclaimBudgetCSSetting(ReclaimBudgetCS__c.getInstance()));
    	} else {
    		System.debug('### No settings, okay');
    	}
    }			     
		     	
}