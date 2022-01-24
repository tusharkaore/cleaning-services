({
    initDataTable: function (component, event, helper) {
        component.set("v.columns", [
            {label: 'Resource Name', fieldName: 'Name', type: 'text'}
        ]);
    },
    
    initPagination: function (component, event, helper) {	
        var pagination ={};
        component.set('v.pagination',pagination);
        component.set('v.pagination.pageNumber',1);
        component.set('v.pagination.numberOfRecords',10);
        component.set('v.pagination.dataSize',0);
        component.set('v.pagination.currentNumberOfRecords',0);
        component.set('v.pagination.totalPages',1);
    },
    
    getAppointments : function(component, event, helper) {
        
        var action = component.get("c.getAllAppointments");
        
        action.setCallback(this, function(res) {
            
            var state = res.getState();
            if(component.isValid() && state === "SUCCESS"){
                var resData = res.getReturnValue();
                resData.forEach(addProps);
                function addProps(item, index) {
                    item.isOpen = false; 
                    item.showCandidates = false;
                }	
                component.set("v.apptDetails", resData);
                component.set("v.pagination.dataSize", resData.length);
                
                helper.pageNumber(component, event, helper);
                helper.setPageDataAsPerPagination(component, event, helper);
            }else{
                var errors = res.getError();
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
    
    getCandidatesHelper : function(component, event, helper) {
        component.set("v.resourceCandidateDetails", []);
        component.set("v.selectedRows", []);
        //component.set("v.showCandidates", true);
        
        var svcApptRecId = event.getSource().get("v.value"); 
        var action = component.get("c.getResourceCandidates");
        action.setParams({svcApptId : svcApptRecId});
        
        action.setCallback(this, function(res) {
            
            var state = res.getState();
            if(component.isValid() && state === "SUCCESS"){
                var resData = res.getReturnValue();
                component.set("v.resourceCandidateDetails", resData);
                
                var apptDetails = component.get("v.pageAppDetails");
                var filteredAppt = apptDetails.filter(showCandidates);
                filteredAppt[0].showCandidates = true; 
                function showCandidates(apptDetail) {
                    return apptDetail.Id == svcApptRecId; 
                }
                component.set("v.pageAppDetails", apptDetails);
                
            }else{
                var errors = res.getError();
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
    
    saveResourceAllocation: function(component, event, helper){
        var selectedResources = component.get("v.selectedRows");
        var svcApptRecId = event.getSource().get("v.value");
        //TODO: validate if required number of rows are selected
        
        if(true){
            var action = component.get("c.saveResourceAllocation");
            action.setParams({	selectedResources : JSON.stringify(selectedResources),
                              svcApptId: svcApptRecId});
            
            action.setCallback(this, function(res) {
                
                var state = res.getState();
                
                if(component.isValid() && state === "SUCCESS"){
                    var resData = res.getReturnValue();
                    component.find('notifLib').showToast({
                        "title": 'Success',
                        "variant": 'success',
                        "message": 'Cleaners Assigend Successfully.'
                    });
                    $A.get('e.force:refreshView').fire();
                }else{
                    var errors = res.getError();
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
        }
    }, 
    
    showMap: function(component, event, helper){
        try{
            var svcApptRecId = event.getSource().get("v.value");
            var apptDetails = component.get("v.apptDetails");
            var filteredApptList  = apptDetails.filter(findAppt);
            function findAppt(apptDetail) {
                return apptDetail.Id == svcApptRecId; 
            }
            var mapMarker = {};
            var location = {};
            var filteredAppt = filteredApptList[0];
            location.Street = filteredAppt.Street;
            location.City = filteredAppt.City;
            location.State = filteredAppt.State;
            location.PostalCode = filteredAppt.PostalCode;
            location.Country = filteredAppt.Country;
            
            mapMarker.location = location;
            mapMarker.title = filteredAppt.Account != null ? filteredAppt.Account.Name : '';
            
            var mapDetails = {};
            var mapMarkers = []; mapMarkers.push(mapMarker); 
            mapDetails.mapMarkers = mapMarkers;
            mapDetails.mapCenter = filteredAppt.City;
            mapDetails.zoomLevel = 12;
            mapDetails.title = filteredAppt.Account != null ? filteredAppt.Account.Name : '';
            component.set("v.mapDetails", mapDetails);
            component.set("v.openMap", true);
        }catch(error){
            component.find('notifLib').showToast({
                "title": 'Error',
                "variant": 'error',
                "message": 'Error while rendering the map'
            });
        }
        
    },
    
     /**
     * Helper method to calculate number of pages
     */
    pageNumber: function (component, event, helper) {
        var record = component.get("v.apptDetails");
        var totalPage = Math.ceil(record.length / component.get("v.pagination.numberOfRecords"));
        component.set("v.pagination.totalPages", Math.ceil(record.length / component.get("v.pagination.numberOfRecords")));
    },
    
    /**
     * Helper method to set Page Data As Per Pagination
     */
    setPageDataAsPerPagination: function (component, event, helper) {
        try {
            var data = [];
            var pageNumber = component.get("v.pagination.pageNumber");
            var numberOfRecords = component.get("v.pagination.numberOfRecords");
            var allData = component.get("v.apptDetails");
            //calculating variable to initaliize in for loop
            var x = (pageNumber - 1) * numberOfRecords;
            //creating data-table data
            for (; x < (pageNumber) * numberOfRecords; x++) {
                if (allData[x]) {
                    data.push(allData[x]);
                }
            }
            component.set("v.pageAppDetails", data);
            component.set("v.pagination.currentNumberOfRecords", (data.length));
        } catch (error) {
            component.find('notifLib').showToast({
                "title": 'Error',
                "variant": 'error',
                "message": error.message
            });
        }
    },
    
})