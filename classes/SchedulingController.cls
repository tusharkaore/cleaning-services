/**
* @description Controller class Scheduling Console and Appointment Details components
* @className SchedulingController
* @author Tushar Kaore
* @lastModified 24/01/2022
*/

public with sharing class SchedulingController {
    public SchedulingController() {

    }

    /**
     * @description Wrapper class to hold the Picklist values and labels  
     */
    public class PicklistDetails {
        /**
        * Label of Picklist record
        */
        @AuraEnabled
        public String label {get;set;}
        /**
        * Value for Picklist record
        */
        @AuraEnabled
        public String value {get;set;}
    }

    /**
     * Fetching list of dropdown values from Status field of ServiceAppointment object
     */
    @AuraEnabled
    public static Object getStatusList(){
        List<PicklistDetails> statusList = new List<PicklistDetails>();
        try {
            Schema.DescribeFieldResult fieldResult = ServiceAppointment.Status.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                PicklistDetails pickOpt = new PicklistDetails();
                pickOpt.label = pickListVal.getLabel();
                pickOpt.value = pickListVal.getValue();
                statusList.add(pickOpt);
            }    
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
        return statusList;
    }

    /**
     * Fetching list of New Appointments to be shown for scheduling 
     */
    @AuraEnabled
    public static Object getAllAppointments(){
        try {
            Map<String, Object> filterMap = new Map<String, Object>();
            filterMap.put('status', 'New');
            filterMap.put('startDate', Datetime.now().format('yyyy-MM-DD'));

            List<ServiceAppointment> svcAppts 
                = (List<ServiceAppointment>) getFilteredList(JSON.serialize(filterMap));

            return svcAppts;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Fetching list of assignments after today to be shown on Full Calendar
     */

    @AuraEnabled
    public static Object fetchResourceAssignments(){
        try {
            List<AssignedResource> resourceAssignments 
                = [ SELECT AssignedResourceNumber,EventId,Id,IsRequiredResource,Role,
                    ServiceAppointmentId, ServiceAppointment.DueDate, ServiceAppointment.AppointmentNumber,
                    ServiceResourceId,ServiceResource.Name, ServiceAppointment.WorkOrder__c, ServiceAppointment.WorkOrder__r.WorkOrderNumber
                    FROM AssignedResource 
                    WHERE ServiceAppointment.DueDate >= LAST_MONTH AND ServiceAppointment.DueDate <= NEXT_MONTH];

            List<ServiceResource> svcResource
                    = [ SELECT AccountId,Description,Id,IsActive,LocationId,Name,
                        RelatedRecordId ,ResourceType FROM ServiceResource WHERE IsActive = true];
            

            Map<String, Object> resultMap = new Map<String, Object>();
            resultMap.put('resourceAssignments', resourceAssignments);
            resultMap.put('svcResource', svcResource);

            return resultMap;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Fetching the list of resources which are free on the given appointment's due date
     */
    @AuraEnabled
    public static Object getResourceCandidates(Id svcApptId){

        try {
            ServiceAppointment svcAppt = [SELECT Id, DueDate FROM ServiceAppointment WHERE Id=: svcApptId];
            //TODO- Add the filter of resources from the territory
            //Getting all the resources list
            Map<Id, ServiceResource> svcResourceMap 
                = new Map<Id, ServiceResource>([SELECT AccountId,Description,Id,IsActive,LocationId,Name,
                                        RelatedRecordId ,ResourceType FROM ServiceResource WHERE IsActive = true]);

            //Get all the booked resources for the given date
            Map<Id, AssignedResource> assignedResourceList 
                = new Map<Id, AssignedResource>([SELECT AssignedResourceNumber,Id,IsRequiredResource,ServiceAppointmentId,
                                                ServiceResourceId,ServiceAppointment.DueDate 
                                                FROM AssignedResource WHERE ServiceAppointment.DueDate = THIS_WEEK]);

            //Removing the already assigned resources on a given date
            for(AssignedResource assignedResource: assignedResourceList.values()){
                if(svcResourceMap.containsKey(assignedResource.ServiceResourceId)){
                    svcResourceMap.remove(assignedResource.ServiceResourceId);
                }
            }

            return svcResourceMap.values();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
    }

    /**
     * Assigning selected resources to the appointment
     */
    @AuraEnabled
    public static Object saveResourceAllocation(String selectedResources, String svcApptId){
        try {
            List<ResourceWrapper> selectedResourcesList =  ResourceWrapper.getList(selectedResources);
            List<AssignedResource> assignedResourceToAdd = new List<AssignedResource>();
            for(ResourceWrapper resource: selectedResourcesList){
                AssignedResource svcAppt = new AssignedResource();
                svcAppt.ServiceAppointmentId = svcApptId;
                svcAppt.ServiceResourceId = resource.Id;
                assignedResourceToAdd.add(svcAppt);
            }
            if(assignedResourceToAdd.size() > 0){
                insert assignedResourceToAdd;

                ServiceAppointment svcAppt 
                    = [SELECT Id, WorkOrder__c FROM ServiceAppointment WHERE Id=: svcApptId];
                WorkOrder workOrder = new WorkOrder(Id=svcAppt.WorkOrder__c);
                workOrder.Status= 'Scheduled';
                update workOrder;

            }
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Filtering appointments as per the users criteria of status and start/end date
     */
    @AuraEnabled
    public static Object getFilteredList(String filtersJson){
        List<ServiceAppointment> results = new List<ServiceAppointment>();
        try {
            Map<String, Object> requestMap =   (Map<String, Object>) JSON.deserializeUntyped(filtersJson);
            String status = (String) requestMap.get('status');
            String startDateStr = (String) requestMap.get('startDate');
            Date startDate = Date.valueOf(startDateStr);
            Datetime startDateTime = startDate;
            String endDateStr = (String) requestMap.get('endDate');
            
            String strQuery =   'SELECT Address,AccountId,Account.Name,ActualDuration,ActualEndTime,ActualStartTime,AdditionalInformation,'+
            'AppointmentNumber,CancellationReason,Comments,ContactId,Description,'+
            'DueDate,Id,OwnerId, Owner.Name, ParentRecordId,ParentRecordType,Status,Subject,'+
            'Street,City,PostalCode,State,Country, WorkOrder__c, WorkOrder__r.WorkOrderNumber, WorkOrder__r.CrewSize__c'+
            ' FROM ServiceAppointment WHERE Status=: status AND DueDate>=: startDateTime';
            
            //Add end date to the WHERE clause if user has provided the value
            if( endDateStr != null){
                Date endDate = Date.valueOf(endDateStr);
                Datetime endDateTime = endDate;
                strQuery+= ' AND DueDate <=: endDateTime';
            }
            results = Database.query(strQuery);
            return results;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}