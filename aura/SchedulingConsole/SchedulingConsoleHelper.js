({
    initAttributes : function(component, event, helper) {
        var filters = {};
        filters.status = 'New';
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        filters.startDate = today;
        component.set("v.filters",filters);
    },
    
    /**
     * Helper method to get filtered list from server
     */
    applyFiltersHelper : function(component, event, helper) {
        var filters = component.get("v.filters");
        filters.statusValues = null;
        this.showSpinner(component);
        var action = component.get("c.getFilteredList");
        action.setParams({filtersJson: JSON.stringify(filters)});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var resData = response.getReturnValue();
                component.set("v.apptDetails", resData);
                var apptDetailsChild = component.find("apptDetails");
                apptDetailsChild.apptListChanged();
                this.hideSpinner(component);
            } else {
                this.hideSpinner(component);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        // log the error passed in to AuraHandledException
                        component.find('notifLib').showToast({
                            "title": 'Error',
                            "variant": 'error',
                            "message": errors[0].message
                        });
                    }
                } 
            }
        });
        $A.enqueueAction(action);
    },
    
    /**
     * Helper method to get status filter dropdown values
     */
    fetchStatusesHelper: function(component, event, helper) {
        this.showSpinner(component);
        var action = component.get("c.getStatusList");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var statusValues = response.getReturnValue();
                var filters = component.get("v.filters") || {};
                filters.statusValues = statusValues;
                component.set("v.filters", filters);
                this.hideSpinner(component);
            }else {
                this.hideSpinner(component);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        // log the error passed in to AuraHandledException
                        component.find('notifLib').showToast({
                            "title": 'Error',
                            "variant": 'error',
                            "message": errors[0].message
                        });
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    
    /**
     * Helper method to get current resource assgnment from server
     */
    getResourceAssignment : function(component, event, helper) {
        
        var action = component.get("c.fetchResourceAssignments");
        
        action.setCallback(this, function(res) {
            
            var state = res.getState();
            
            if(component.isValid() && state === "SUCCESS"){
                var resData = res.getReturnValue();
                //component.set("v.resourceAssignment", resData);
                var calData = helper.createCalendarData(component, resData);
                helper.initCalendar(component, calData);
            }else{
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        // log the error passed in to AuraHandledException
                        component.find('notifLib').showToast({
                            "title": 'Error',
                            "variant": 'error',
                            "message": errors[0].message
                        });
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    /**
     * Helper method to translate assignment data for Full Calendar
     */
    createCalendarData: function(component, dataMap) {
        
        var resourceAssignments = [];
        const resourcesMap = new Map();
        var assignments = dataMap.resourceAssignments;
        var svcResource = dataMap.svcResource;

        for (var index = 0; index < assignments.length; index++) {
            
            var assignment = assignments[index];
            var startdate = $A.localizationService.formatDate(assignment.ServiceAppointment.DueDate);
            var enddate = $A.localizationService.formatDate(assignment.ServiceAppointment.DueDate);
            
            resourceAssignments.push({
                title: assignment.ServiceAppointment.WorkOrder__r.WorkOrderNumber,
                start: startdate,
                end: enddate,
                id: assignment.Id, 
                apptId: assignment.ServiceAppointmentId,
                workOrderId: assignment.ServiceAppointment.WorkOrder__c,
                resourceId : assignment.ServiceResourceId
            });
        }

        for (var index = 0; index < svcResource.length; index++) {
            var resource = svcResource[index];
            var ownerDetails = {};
            ownerDetails.group = 'All';
            ownerDetails.id = resource.Id;
            ownerDetails.title = resource.Name;
            resourcesMap.set(resource.Id, ownerDetails);
        }

        var result = { 'assignmentsArray' : resourceAssignments, 'resourcesMap' : resourcesMap}; 
        return result;
    }, 
    
    initCalendar: function(component, calData) {
        try{		
            // get some data here
            var evtData = calData.assignmentsArray;
            var resourceData = Array.from(calData.resourcesMap.values());
            var ele = component.find('calendar').getElement();
            $(ele).fullCalendar({
                schedulerLicenseKey: 'CC-Attribution-NonCommercial-NoDerivatives',
                
                slotDuration: {days:1},
                header: {
                    left: 'prev,next today',
                    center: 'title',
                    right: 'timelineDay,timelineWeek'
                },
                defaultView: 'timelineWeek',
                resourceGroupField: 'group',
                displayEventTime: false,
                resources: resourceData,
                events: evtData,
                
                eventClick: function(event, jsEvent, view) {
                    window.open('/' + event.workOrderId);  
                },
                
                
            });
        }
        catch(error){
            component.find('notifLib').showToast({
                "title": 'Error',
                "variant": 'error',
                "message": 'Error while rendering the calendar'
            });
        }
        
    }, 
    
    showSpinner: function(component) {
        component.set("v.spinner", true);
    },
    
    hideSpinner: function(component) {
        component.set("v.spinner", false);
    }
    
    
})