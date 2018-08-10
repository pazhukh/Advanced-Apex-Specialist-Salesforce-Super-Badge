/**
* @name orderTrigger
* @description
**/
trigger orderTrigger on Order (after update) {
   
    if(Trigger.new != null) {
        
        OrderHelper.AfterUpdate(Trigger.new, Trigger.old);
    }
}