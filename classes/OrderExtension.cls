/**
* @name OrderExtension
* @description This class is provided for you to facilitate the Super Badge
**/
public class OrderExtension {
    
    public Order orderRecord {get;set;}
    public List<OrderItem> orderItemList {get;set;}
    public String selectedFamily {get;set;}
    public List<chartHelper.chartData> pieData {get;set;}
    public Decimal total {get;set;}
    
    public Map<Id,OrderItem> orderItemMap;
    ApexPages.StandardSetController standardSetController;
    
    public OrderExtension(ApexPages.StandardController standardController){
        orderRecord = (Order)standardController.getRecord();
        orderItemMap = new Map<id,OrderItem>();
        if ( orderRecord.Id != null ){
            orderRecord = queryOrderRecord(orderRecord.Id);
        }
        loadInitialOrderItemData();
        loadPriceBookentry();
        
    }
    
    public void loadPriceBookentry() {
        String query = 'SELECT Name, Id, Pricebook2Id, Product2Id, UnitPrice, Product2.Name,Product2.Quantity_Remaining__c, Product2.Family FROM PricebookEntry WHERE isActive= true';
        if (String.isNotBlank(selectedFamily) && selectedFamily != Constants.SELECT_ONE ) {
            query += ' AND Product2.Family = \''+ selectedFamily + '\'';
        }
        /*if (orderRecord.Id != null) {
query += ' AND Product2Id in (select Product2Id from OrderItem where orderId= \''+ orderRecord.Id + '\')';
}*/
        
        
        standardSetController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
        standardSetController.setPageSize(Constants.DEFAULT_ROWS);
        
        loadOrderItem();
    }
    
    public void loadOrderItem() {
        orderItemList = new List<OrderItem>();
        if(standardSetController.getRecords()!=null && standardSetController.getRecords().size() > 0) {
            for (SObject  obj : standardSetController.getRecords()) {
                PricebookEntry entry = (PricebookEntry)obj;
                
                if(orderItemMap.containsKey(entry.product2Id)) {
                    orderItemList.add(orderItemMap.get(entry.product2Id));
                } else{
                    OrderItem item = new OrderItem(
                        Quantity = 0,
                        PricebookEntryId = entry.Id,
                        Product2Id = entry.Product2Id,
                        UnitPrice = entry.UnitPrice,
                        Product2 = entry.Product2
                    );
                    orderItemList.add(item);
                    orderItemMap.put(entry.Product2Id, item);
                }
            }
        }
        
    }
    
    public void loadInitialOrderItemData() {
        for(OrderItem item : orderRecord.OrderItems) {
            orderItemMap.put(item.Product2Id, item);
        }
        loadChartData();
    }
    
    public void loadChartData() {
        this.total = 0;
        pieData = new List<ChartHelper.ChartData>();
        for(OrderItem item : orderItemMap.values()) {
            pieData.add(new ChartHelper.ChartData(item.Product2.Name, (item.UnitPrice * item.Quantity)));
            total = total + (item.UnitPrice*item.Quantity);
        }
    }
    
    //ToDo: Implement your own method to populate orderItemList
    //  that you will call after pagination and/or family selection
    
    
    /**
* @name OnFieldChange
* @description
**/
    public void OnFieldChange(){
        //ToDo: Implement logic to store the values changed on the page
        //      and populate pieData
        //      and populate total
        
        for(OrderItem item : orderItemList){
            orderItemMap.put(item.Product2Id, item);
        }
        
        loadChartData();
        
    }
    
    /**
* @name SelectFamily
* @description
**/
    public void SelectFamily(){
        //ToDo: Implement logic to filter based on the selected product family
        loadPriceBookentry();
    }
    
    /**
* @name Save
* @description
**/
    public void Save(){
        //ToDo: Implement logic to save the Order and populated OrderItems
        /*System.Savepoint sp = Database.setSavepoint();
        
        try {
            if(orderRecord.Pricebook2Id == null) {
                orderRecord.Pricebook2Id = Constants.STANDARD_PRICEBOOK_ID;
            }
            upsert orderRecord;
            
            List<OrderItem> insertItems = new List<OrderItem>();
            List<OrderItem> deleteItems = new List<OrderItem>();
            
            for (OrderItem item : orderItemMap.values()) {
                if(item.Quantity > 0) {
                    if(item.OrderId == null) {
                        item.OrderId = orderRecord.Id;
                    }
                    insertItems.add(item);
                } else if(item.Id != null) {
                    OrderItem newItem = new OrderItem();
                    newItem.id=item.Id;
                    deleteItems.add(newItem);
                    item.Id = null;
                }
            }
            
            upsert insertItems;
            delete deleteItems;
            
        } catch (Exception e){
            Database.rollback(sp);
            apexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO,Constants.ERROR_MESSAGE));
        }*/
        
        System.Savepoint sp = Database.setSavepoint();

    try {
      if(orderRecord.Pricebook2Id == null) {
        orderRecord.Pricebook2Id = Constants.STANDARD_PRICEBOOK_ID;
      }
      upsert orderRecord;

      List<OrderItem> orderItemsToUpsert = new List<OrderItem>();
      List<OrderItem> orderItemsToDelete = new List<OrderItem>();

      for (OrderItem oi : orderItemMap.values()) {
        if(oi.Quantity > 0) {
          if(oi.OrderId == null) {
            oi.OrderId = orderRecord.Id;
          }
          orderItemsToUpsert.add(oi);
        } else if(oi.Id != null) {
          orderItemsToDelete.add(new OrderItem(id=oi.Id));
          oi.Id = null;
        }
      }

      upsert orderItemsToUpsert;
      delete orderItemsToDelete;

    } catch (Exception e){
      Database.rollback(sp);
      apexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO,Constants.ERROR_MESSAGE));
    }
    }
    
    
    /**
* @name First
* @description
**/
    public void First(){
        standardSetController.first();
        loadOrderItem();
    }
    
    
    /**
* @name Next
* @description
**/
    public void Next(){
        standardSetController.next();
        loadOrderItem();
    }
    
    
    /**
* @name Previous
* @description
**/
    public void Previous(){
        standardSetController.previous();
        loadOrderItem();
    }
    
    /**
* @name Last
* @description
**/
    public void Last(){
        standardSetController.last();
        loadOrderItem();
    }
    
    /**
* @name GetHasPrevious
* @description
**/
    public Boolean GetHasPrevious(){
        return standardSetController.getHasPrevious();
    }
    
    /**
* @name GetHasNext
* @description
**/
    public Boolean GetHasNext(){
        return standardSetController.getHasNext();
    }
    
    /**
* @name GetTotalPages
* @description
**/
    public Integer GetTotalPages(){
        return (Integer)math.ceil(standardSetController.getResultSize()/(Decimal)Constants.DEFAULT_ROWS);
    }
    
    /**
* @name GetPageNumber
* @description
**/
    public Integer GetPageNumber(){
        return standardSetController.getPageNumber();
    }
    
    /**
* @name GetFamilyOptions
* @description
**/
    public List<SelectOption> GetFamilyOptions(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(Constants.SELECT_ONE,Constants.SELECT_ONE));
        for(Schema.PicklistEntry entry : Constants.PRODUCT_FAMILY){
            options.add(new SelectOption(entry.getLabel(),entry.getValue()));
        }
        return options;
    }
    
    /**
* @name QueryOrderRecord
* @description
**/
    public static Order QueryOrderRecord(Id orderId){
        return [
            SELECT Id, AccountId, EffectiveDate, Name, Status, Pricebook2Id,
            (
                SELECT Id, OrderId, Quantity, UnitPrice, PricebookEntryId, Product2Id,
                Product2.Name, Product2.Family, Product2.Quantity_Remaining__c
                FROM OrderItems
            )
            FROM Order
            WHERE Id = :orderId
        ];
    }
    
}