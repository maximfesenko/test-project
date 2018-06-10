public class BookingController {
    
    public BookingRoom__c searchRoom { get; set; }
    
    public BookingController() {
        this.searchRoom = new BookingRoom__c();
    }
    
    public void doSearch() {
        
        ApexPages.getMessages().clear();
        
        List<String> condition = new List<String>();
        Date dateFrom = this.searchRoom.DateFrom__c;
        Date dateTo = this.searchRoom.DateTo__c;
        Id roomId = this.searchRoom.Room__c;
        Id addonId = this.searchRoom.Addon__c;
        if (roomId != null && addonId == null) {
            condition.add('Room__c = :roomId');
        } else if (roomId == null && addonId != null) {
            condition.add('Addon__c = :addonId');
        } else if (roomId != null && addonId != null) {
            condition.add('Room__c = :roomId AND Addon__c = :addonId');
        }
        
        String query = 'SELECT Value__c, Room__c, Addon__c, DateFrom__c, DateTo__c ' + 
            ' FROM Price__c ' + 
            ' WHERE ' + String.join(condition, ' AND ') + 
              ' AND DateFrom__c <= :dateFrom ' +
              ' AND DateTo__c >= :dateTo ' + 
            ' LIMIT 1000';

        List<Price__c> prices = (List<Price__c>)Database.query(query);
       
        for (Price__c price : prices) {
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.Severity.CONFIRM, 
                    'Price=' + price.Value__c + '-(Room)' + price.Room__c + '-(Addon)' + price.Addon__c
                )
            );
        }
    }
    
    public void doCalculate() {
        ApexPages.getMessages().clear();
        
        if (this.searchRoom.DateFrom__c > this.searchRoom.DateTo__c) {
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.Severity.ERROR, 
                    'Date From can not be greater than Date To'
                )
            );
            return;
        }
        
        List<String> condition = new List<String>();
        Date dateFrom = this.searchRoom.DateFrom__c;
        Date dateTo = this.searchRoom.DateTo__c;
        Id roomId = this.searchRoom.Room__c;
        Id addonId = this.searchRoom.Addon__c;
        if (roomId != null && addonId == null) {
            condition.add('Room__c = :roomId');
        } else if (roomId == null && addonId != null) {
            condition.add('Addon__c = :addonId');
        } else if (roomId != null && addonId != null) {
            condition.add('Room__c = :roomId AND Addon__c = :addonId');
        }
        
        String query = 'SELECT Value__c, Room__c, Addon__c, DateFrom__c, DateTo__c ' + 
            ' FROM Price__c ' + 
            ' WHERE ' + String.join(condition, ' AND ') + 
              ' AND DateFrom__c <= :dateFrom ' +
              ' AND DateTo__c >= :dateTo ' + 
            ' ORDER BY Value__c ASC ' + 
            ' LIMIT 1000';

        List<Price__c> prices = (List<Price__c>)Database.query(query);
        
        if (prices.isEmpty()) {
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.Severity.ERROR, 
                    'There is no any price by your search condition.'
                )
            );
            return;
        }
        
		Price__c roomPrice = new Price__c();
        Price__c addonPrice = new Price__c();
        for (Price__c price : prices) {
            if (price.Room__c != null) {
                roomPrice = price;
            }
            if (price.Addon__c != null) {
                addonPrice = price;
            }
        }

        Decimal roomAmount = 0.0;
        Decimal addonAmount = 0.0;
        Integer allocation = this.searchRoom.DateFrom__c.daysBetween(this.searchRoom.DateTo__c) + 1;
        if (roomPrice.Id != null) {
            roomAmount = roomPrice.Value__c * allocation;
        }
        
        if (addonPrice.Id != null) {
            addonAmount = addonPrice.Value__c * allocation;
        }
        
        //create BookingRoom
        insert new BookingRoom__c(
            Room__c = this.searchRoom.Room__c,
            Addon__c = this.searchRoom.Addon__c,
            DateFrom__c = this.searchRoom.DateFrom__c,
            DateTo__c = this.searchRoom.DateTo__c,
            TotalPrice__c = roomAmount + addonAmount
        );
    }
}