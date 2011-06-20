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

/**
 * This class is an abstraction for all the budget level classes: Budgets, ProgramBudget, BudgetLine and PurchaseRequest
 * If instantiated, means it is the root containing all the first level Budgets
 * Pattern used: template method. Uses properties for easy handling.
 */
public virtual class BudgetNode{
		
	public Integer Id{get;set;}
	public Decimal approvedRouteTotal{get;set;}
	public Decimal requestedRouteTotal{get;set;}
	public Decimal savedApproved{get;set;}
	public List<BudgetNode> children{get;set;}
	public Boolean collapsed{get;set;}
	public BudgetNode parent{get;set;}
	
	public String name{
		get{return getNameO();}
		set{setNameO(value);}
	}
	
	public virtual String getNameO(){ return null;}
	public virtual void setNameO(String name){}
	
	
	
	public Decimal approved{
		get{return getApprovedO();}
		set{ setApprovedO(value);}
	}
	public virtual Decimal getApprovedO(){
		return approvedRouteTotal;
	}	
	public virtual void setApprovedO(Decimal d){
		approvedRouteTotal = d;
	}
	
	public Decimal requested{
		get{return getRequestedO();}
		set{setRequestedO(value);}
	}
	public virtual Decimal getRequestedO(){
		return requestedRouteTotal;
	}
	public virtual void setRequestedO(Decimal d){
		requestedRouteTotal = d;
	}
	
	public Decimal approvedTotal{
		get{return getApprovedTotalO();}
		set{}
	}
	public virtual Decimal getApprovedTotalO(){
		Decimal sum = 0;
		for(BudgetNode b: children){
			if(b.approved != null){
				sum += b.approved;
			}
		}
		return sum;
	}
	
	public String requestedS{
		get{return BudgetUtil.formatDecimal(requested);}
		set{requested = BudgetUtil.parseDecimal(value);}
	}
	
	public String approvedS{
		get{return BudgetUtil.formatDecimal(approved);}
		set{approved = BudgetUtil.parseDecimal(value);}
	}
	
	public String remainingS{
		get{return BudgetUtil.formatDecimal((approved==null?0:approved)-approvedTotal);}
		set{}
	}
	
	public String approvedTotalS{
		get{return BudgetUtil.formatDecimal(approvedTotal);}
		set{}
	}
		
	public Decimal BLApprovedUncommitted{
		get{return getBLApprovedUncommittedO();}
	}
	
	public virtual Decimal getBLApprovedUncommittedO(){
		return null;
	}
	
	public String BLApprovedUncommittedS{
		get{ return BLApprovedUncommitted == null ? '' : BudgetUtil.formatDecimal(BLApprovedUncommitted); }
	}
	
	public Id objId{
		get{return getObjIdO();}
	}
	public virtual Id getObjIdO(){
		return null;
	}
	
	public String Region{
		get{return getRegionO();}
	}	
	public String getRegionO(){
		return null;
	}
	
	public Integer Level{
		get{return getLevelO();}
	}
	public virtual Integer getLevelO(){
		return 0;
	}
	
	public Boolean isNew{get{
		return objId == null;
	}}
	
	public BudgetNode(Integer id){
		this.collapsed = true;
		this.id = id;
		this.requestedRouteTotal = 0;
		this.approvedRouteTotal = 0;
		this.children = new List<BudgetNode>();
		this.parent = null;
	}
	
	public void add(BudgetNode n){
		children.add(n);
		n.parent = this;
	}
		
	public void resetAmounts(){
		savedApproved = approved;
		for(BudgetNode b: children){
			b.resetAmounts();
		}
	}
}