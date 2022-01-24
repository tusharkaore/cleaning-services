/**
* @description This class is used to create Payment records for Resources/Cleaners twice every month
* @className PaymentCalculationsBatch
* @author Tushar Kaore
* @lastModified 01/24/2022
*/

public class PaymentCalculationsBatch implements Schedulable, Database.Batchable<sObject>{

    public final String Query;
    public String flRecordTypeId;
           
    public PaymentCalculationsBatch()
    {
        query ='SELECT AccountId,Id,IsActive,LocationId,Name,OwnerId,'+
                'RelatedRecordId,ResourceType FROM ServiceResource';
    }   

    /**
     * Start method to fetch list of all Service Resources
     */
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    /**
     * Fetches the list of Resouce Assignment for completed Work Line Items and creates 
     * Payment records for two halves of the month
     * @param BC Batch context variable
     * @param scope Batch scope, Resource records to operate on
     * @return void
     */

    public void execute(Database.BatchableContext BC,List<ServiceResource> scope){
            String identifierString;
            List<ResourcePayment__c> paymentsToAdd = new List<ResourcePayment__c>();
            /**
            * Batch should be run for every Resource to avoid hitting Governor Limits
            */
            if( scope != null && scope.size() == 1 ){
                
                ServiceResource serviceResource = scope[0]; 
                Map<Id,Double> resourceAmountMap = new Map<Id,Double>();
                List<Id> workLineItemIds = new List<Id>();

                //Variable for date filter range
                Date todayDate = System.today();  
                Date startDate; 
                Date endDate;

                if(todayDate.day() < 15){
                    //run batch for the last month second half if current date is less than 15
                    date lastMonthDate = todayDate.addMonths(-1);
                    startDate = Date.newInstance(lastMonthDate.year(), lastMonthDate.month(),15);
                    Integer numberDays = date.daysInMonth(lastMonthDate.year(), lastMonthDate.month());
                    endDate = date.newInstance(lastMonthDate.year(), lastMonthDate.month(), numberDays);
                    identifierString = 'SecondHalf-' + lastMonthDate.month() + '-' + lastMonthDate.year() +
                                        '-' + serviceResource.Id;
                }else{
                    //run batch for the last month second half if current date is greater than 15
                    date currentMonthDate = todayDate;
                    startDate = Date.newInstance(currentMonthDate.year(), currentMonthDate.month(),1);
                    endDate = date.newInstance(currentMonthDate.year(), currentMonthDate.month(), 14);
                    identifierString = 'FirstHalf-' + currentMonthDate.month() + '-' + currentMonthDate.year() +
                                        '-' + serviceResource.Id;
                }

                /*
                 * Getting all the Resource Assignment records where Service Appoitnmetn is complete and 
                 * falls between the required timeframe
                 */
                List<AssignedResource> resourceAssignments 
                    = [ SELECT AssignedResourceNumber,Id,IsRequiredResource,ServiceAppointment.ParentRecordId,Role,
                        ServiceAppointmentId,ServiceAppointmentStatus__c,ServiceResourceId 
                        FROM AssignedResource 
                        WHERE ServiceResourceId=: serviceResource.Id AND
                        ServiceAppointment.Status='Completed' AND ServiceAppointment.ParentRecordType ='WorkOrderLineItem'
                        AND ServiceAppointment.DueDate >=: startDate
                        AND ServiceAppointment.DueDate <=: endDate];

                /*
                 * Capturing associated Work Line Items which as amount fields
                 */       
                for(AssignedResource assgndResource: resourceAssignments){
                    workLineItemIds.add(assgndResource.ServiceAppointment.ParentRecordId);
                }

                /*
                 * Fetching list of associated Work Line Items which as amount fields
                 */

                Map<Id, WorkOrderLineItem> lineItemsMap = 
                    new Map<Id, WorkOrderLineItem>(
                        [SELECT Id, Quantity, TotalPrice FROM WorkOrderLineItem 
                        WHERE Id IN: workLineItemIds]
                    );

                /*
                 * Calculating due amount considering the number of resources on line item and 50-50 share between
                 * company and resource/cleaner 
                 */
                Double dueAmt = 0;
                for(WorkOrderLineItem lineItem: lineItemsMap.values()){
                    dueAmt = dueAmt + (lineItem.TotalPrice/lineItem.Quantity/2);
                }
                
                //Creating payment record with due amount
                ResourcePayment__c payment = new ResourcePayment__c();
                payment.ServiceResource__c = serviceResource.Id;
                payment.Amount__c = dueAmt;
                payment.PayStatus__c = 'Due';
                payment.Identifier__c = identifierString;
                paymentsToAdd.add(payment);
                upsert paymentsToAdd Identifier__c;
                
                    
            }else{
                /**
                 * Aborting the job to run with Scope Size = 1
                 * Batch should be run for every Resource to avoid hitting Governor Limits
                 */
                System.abortJob(BC.getJobId());
            }
    }    
    
    public void finish(Database.BatchableContext BC){
    } 

    //Schedule execution
    public void execute( SchedulableContext SC ) {  
        Database.executeBatch(this, 1);        
    }
}