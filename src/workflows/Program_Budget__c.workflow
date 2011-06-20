<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Program_External</fullName>
        <field>Program_Budget_External__c</field>
        <formula>Name</formula>
        <name>Update Program External</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>insert_descr</fullName>
        <field>Description__c</field>
        <formula>Name</formula>
        <name>insert descr</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>insert_program_ext</fullName>
        <field>Program_Budget_External__c</field>
        <formula>Name</formula>
        <name>insert program ext</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>insert_program_line_name</fullName>
        <field>Name</field>
        <formula>Budget_Owner__r.Name &amp; &quot;:&quot; &amp; text(Program_Type__c)</formula>
        <name>insert program line name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update_descr</fullName>
        <field>Description__c</field>
        <formula>if( ISNEW() ,Name, Description__c)</formula>
        <name>update descr</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update_program_ext</fullName>
        <field>Program_Budget_External__c</field>
        <formula>Name</formula>
        <name>update program ext</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update_program_line_name</fullName>
        <field>Name</field>
        <formula>if( OR(ISNULL(Short_Name__c),ISBLANK(Short_Name__c)),
Budget_Owner__r.Name &amp; &quot;: &quot; &amp; text(Program_Type__c) ,

Budget_Owner__r.Name &amp; &quot;: &quot; &amp; text(Program_Type__c) &amp; &quot;: &quot; &amp;  Short_Name__c)</formula>
        <name>update program line name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>update program line name</fullName>
        <actions>
            <name>Update_Program_External</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>update_program_line_name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Program_Budget__c.CreatedDate</field>
            <operation>greaterOrEqual</operation>
            <value>1/1/2000</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
