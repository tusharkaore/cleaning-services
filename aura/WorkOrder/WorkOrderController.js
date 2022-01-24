({
    /**
	 * 'init' handler for the component
	 */
    doInit : function(component, event, helper) {
        
        var schedule = {}; 
        schedule.selectedDays = [];
        component.set("v.schedule", schedule);
    },
    
    /**
	 * Handler for week days selection
	 */
    checkboxClicked: function(component, event, helper) {
        helper.checkboxClickedHelper(component, event, helper);
    },
    
    /**
	 * Handler for save button
	 */
    saveRecurrence: function(component, event, helper) {
        helper.saveRecurrenceHelper(component, event, helper);
    }
})