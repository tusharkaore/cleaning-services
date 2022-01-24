({
    
    /**
	 * Helper method to capture the week recurrence pattern
	 */
    checkboxClickedHelper: function(component, event, helper){
        var day = event.currentTarget.id;
        var checked = event.currentTarget.checked;
        var schedule = component.get("v.schedule");
        
        switch (day) {
            case 'sunday':
                schedule.sunday = checked;
                break;
            case 'monday':
                schedule.monday = checked;
                break;
            case 'tuesday':
                schedule.tuesday = checked;
                break;
            case 'wednesday':
                schedule.wednesday = checked;
                break;
            case 'thursday':
                schedule.thursday = checked;
                break;
            case 'friday':
                schedule.friday = checked;
                break;
            case 'saturday':
                schedule.saturday = checked;
        }
        component.set("v.schedule", schedule);
    },
    
    /**
	 * Helper method to create recurring work orders as per user selection
	 */
    saveRecurrenceHelper : function(component, event, helper){
        
        helper.showSpinner(component);
        var schedule = component.get("v.schedule");
        var recId = component.get("v.recordId"); 
        var action = component.get("c.createRecurringWorkOrders");
        action.setParams({	scheduleJsonStr : JSON.stringify(schedule),
                            currentWorkOrderId: recId});
        
        action.setCallback(this, function(res) {
            
            var state = res.getState();
            if(component.isValid() && state === "SUCCESS"){
                var resData = res.getReturnValue();
                component.find('notifLib').showToast({
                    "title": 'Success',
                    "variant": 'success',
                    "message": 'Recurring Jobs created successfully.'
                });
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();

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

            helper.hideSpinner(component);
        });
        $A.enqueueAction(action);
        
    }, 

    showSpinner: function(component) {
        component.set("v.spinner", true);
    },
    
    hideSpinner: function(component) {
        component.set("v.spinner", false);
    }
    
})