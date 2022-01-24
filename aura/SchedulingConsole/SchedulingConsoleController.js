({
    afterScriptsLoaded : function(component, event, helper) {
        helper.initAttributes(component,event,helper);
        helper.fetchStatusesHelper(component,event,helper);
        helper.getResourceAssignment(component, event, helper);
    }, 
    
    applyFilters: function(component, event, helper) {
        helper.applyFiltersHelper(component, event, helper);
    }
})