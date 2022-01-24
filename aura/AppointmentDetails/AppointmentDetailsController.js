({
    doInit : function(component, event, helper) {
        var schedule = {}; 
        schedule.selectedDays = [];
        component.set("v.schedule", schedule);
        
        helper.initDataTable(component, event, helper);
        helper.getAppointments(component, event, helper);
        helper.initPagination(component,event,helper);
    }, 

 
    apptListChanged : function(component, event, helper) {
        var apptDetails = component.get("v.apptDetails");
        component.set("v.pagination.dataSize", apptDetails.length);
        helper.pageNumber(component, event, helper);
        helper.setPageDataAsPerPagination(component, event, helper);
    },
    
    
    getCandidates : function(component, event, helper) {
        helper.getCandidatesHelper(component, event, helper);
    },
    
    handleSaveResources: function(component, event, helper) {
        helper.saveResourceAllocation(component, event, helper);
    }, 
    
    handleShowMap : function(component, event, helper) {
        helper.showMap(component, event, helper);
    }, 
    
    onApptClick : function(component, event, helper) {
        var selectedItem = event.currentTarget;
        var apptid = selectedItem.dataset.apptid;
        var apptDetails = component.get("v.pageAppDetails");
        apptDetails.forEach(toggleIsOpen); 
        function toggleIsOpen(apptDetail) {
            if(apptDetail.Id == apptid){
                apptDetail.isOpen = true;
            }else{
                apptDetail.isOpen = false;
                apptDetail.showCandidates = false;
            }
        }
        component.set("v.pageAppDetails", apptDetails);
    }, 
    
    handleResourceSelection : function(component, event, helper) {
        var selectedRows = event.getParam('selectedRows');
        component.set("v.selectedRows", selectedRows);
    }, 
    
    closeModal: function(component){
        component.set("v.openMap", false);
    }, 
    
    /**
	 * Controller function called when user clicks on Next button on the screen
	 */
    handleNext: function (component, event, helper) {
        var pageNumber = component.get("v.pagination.pageNumber");
        component.set("v.pagination.pageNumber", pageNumber + 1);
        helper.setPageDataAsPerPagination(component, event, helper);
    },
    
    /**
	 * Controller function called when user clicks on Previous button on the screen
	 */
    handlePrev: function (component, event, helper) {
        var pageNumber = component.get("v.pagination.pageNumber");
        component.set("v.pagination.pageNumber", pageNumber - 1);
        helper.setPageDataAsPerPagination(component, event, helper);
    },
    
    /**
	 * Controller function called when user clicks on << (first page)
	 */
    handleFirst: function (component, event, helper) {
        var itemPerPages = component.get('v.pagination.numberOfRecords');
        component.set('v.pagination.numberOfRecords', itemPerPages);
        component.set('v.pagination.currentNumberOfRecords',itemPerPages);
        component.set('v.pagination.pageNumber',1);
        helper.pageNumber(component, event, helper);
        helper.setPageDataAsPerPagination(component, event, helper);
    },
    
    /**
	 * Controller function called when user clicks on >> (last page)
	 */
    handleLast: function (component, event, helper) {
        component.set('v.pagination.pageNumber',component.get('v.pagination.totalPages'));
        var dataSize = component.get('v.apptDetails').length;
        component.set('v.pagination.currentNumberOfRecords', dataSize);
        helper.pageNumber(component, event, helper);
        helper.setPageDataAsPerPagination(component, event, helper);
    },
    
    
    
    
})