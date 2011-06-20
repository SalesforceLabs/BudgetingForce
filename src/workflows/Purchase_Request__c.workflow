<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Alert_sourcing</fullName>
        <field>Alert_Sourcing__c</field>
        <formula>&quot;True&quot;</formula>
        <name>Alert sourcing</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Blank_out_Change_Request_Amount</fullName>
        <field>Change_Request_Amount__c</field>
        <name>Blank out Change Request Amount</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Blank_out_Contractor_Change_Request_Amt</fullName>
        <field>Contractor_Change_Request_Amount__c</field>
        <name>Blank out Contractor Change Request Amt</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>New_PR_Amount</fullName>
        <field>Purchase_Request_Amount__c</field>
        <formula>If( ISPICKVAL(PRIORVALUE(Request_Action__c),&quot;Change Request - Increase&quot;), Purchase_Request_Amount__c +  Change_Request_Amount__c , If( ISPICKVAL(PRIORVALUE(Request_Action__c),&quot;Change Request - Decrease&quot;), Purchase_Request_Amount__c - Change_Request_Amount__c, Purchase_Request_Amount__c))</formula>
        <name>New PR Amount</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>No_PO_Required</fullName>
        <field>PO__c</field>
        <formula>if((Total_PR_Amount_with_Changes__c  &lt;= 5000),  &quot;No PO Required&quot;, PO__c )</formula>
        <name>No PO Required</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Status_New</fullName>
        <field>Status__c</field>
        <literalValue>New/Not Submitted</literalValue>
        <name>Status New</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Status_change_request</fullName>
        <field>Status__c</field>
        <literalValue>Change Request</literalValue>
        <name>Status change request</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_contractor_amt</fullName>
        <field>Purchase_Request_Contractor_Amount__c</field>
        <formula>If( ISPICKVAL(PRIORVALUE(Request_Action__c),&quot;Change Request - Increase&quot;),  Purchase_Request_Contractor_Amount__c  +  Contractor_Change_Request_Amount__c  , If( ISPICKVAL(PRIORVALUE(Request_Action__c),&quot;Change Request - Decrease&quot;), Purchase_Request_Contractor_Amount__c - Contractor_Change_Request_Amount__c, Purchase_Request_Contractor_Amount__c))</formula>
        <name>Update contractor amt</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>alert_sourcing_reset</fullName>
        <field>Alert_Sourcing__c</field>
        <name>alert sourcing reset</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>remove_request_action</fullName>
        <field>Request_Action__c</field>
        <name>remove request action</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>request_action_blank</fullName>
        <field>Request_Action__c</field>
        <name>request action blank</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>status_approved</fullName>
        <field>Status__c</field>
        <literalValue>Approved</literalValue>
        <name>status approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>status_in_progress</fullName>
        <field>Status__c</field>
        <literalValue>In Process</literalValue>
        <name>status in progress</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>status_submitted</fullName>
        <field>Status__c</field>
        <literalValue>Submitted</literalValue>
        <name>status submitted</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update_PR_Name</fullName>
        <field>Name</field>
        <formula>&quot;:&quot; &amp;  Name</formula>
        <name>update PR Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>update contractor purchase req amt</fullName>
        <actions>
            <name>Blank_out_Contractor_Change_Request_Amt</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_contractor_amt</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>remove_request_action</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Purchase_Request__c.Status__c</field>
            <operation>equals</operation>
            <value>Approved</value>
        </criteriaItems>
        <criteriaItems>
            <field>Purchase_Request__c.RecordTypeId</field>
            <operation>equals</operation>
            <value>Contractor Spend</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>update purchase req amt</fullName>
        <actions>
            <name>Blank_out_Change_Request_Amount</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>New_PR_Amount</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>remove_request_action</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Purchase_Request__c.Status__c</field>
            <operation>equals</operation>
            <value>Approved</value>
        </criteriaItems>
        <criteriaItems>
            <field>Purchase_Request__c.RecordTypeId</field>
            <operation>equals</operation>
            <value>Program Spend</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
