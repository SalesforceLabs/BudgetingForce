<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Budget_Name</fullName>
        <field>Name</field>
        <formula>Period__r.Name &amp; &quot; &quot; &amp; text(  Budget_Area__c )</formula>
        <name>Update Budget Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update_ext_name</fullName>
        <field>budget_owner_name_external__c</field>
        <formula>Name</formula>
        <name>update ext name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>update budget name</fullName>
        <actions>
            <name>Update_Budget_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>update_ext_name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Budgets__c.CreatedDate</field>
            <operation>greaterThan</operation>
            <value>1/1/2000</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
