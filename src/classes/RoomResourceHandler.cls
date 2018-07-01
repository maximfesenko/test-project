@RestResource(urlMapping='/booking_flight')
global with sharing class RoomResourceHandler  {

    @HttpPost
    global static String create() {
        Map<String, Object> result = new Map<String, Object>();

        //Handle Request
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        Map<String, Object> params = new Map<String, Object>();
        try {
            params = (Map<String, Object>)JSON.deserializeUntyped(request.requestBody.toString());
        } catch(JSONException ex) {
            result.put('message', ex.getMessage() + ' StackTrace: ' + ex.getStackTraceString());
            result.put('status', 'failed');

            return JSON.serialize(result);
        }

        //Find rooms by days
        Date dateFrom = Date.valueOf(params.get('date_from').toString());
        Date dateTo = Date.valueOf(params.get('date_to').toString());
        List<Price__c> availablePrices = [
            SELECT Room__r.MaxPeople__c, Value__c
            FROM Price__c
            WHERE DateFrom__c <= :dateFrom AND DateTo__c >= :dateTo AND Room__r.MaxPeople__c > 0
            LIMIT 1
        ];

        //Book Room
        if ( ! availablePrices.isEmpty()) {

            Decimal totalPrice = (dateFrom.daysBetween(dateTo) + 1) * availablePrices.get(0).Value__c;

            try {
                insert new BookingRoom__c(
                    DateFrom__c = dateFrom,
                    DateTo__c = dateTo,
                    TotalPrice__c = totalPrice,
                    Room__c = availablePrices.get(0).Room__c
                );

                result.put('message', 'Booked Successfully!');
                result.put('status', 'booked');
                result.put('price', totalPrice);
            } catch(DMLException ex) {
                result.put('message', ex.getMessage() + ' StackTrace: ' + ex.getStackTraceString());
                result.put('status', 'failed');
            }
        } else {
            result.put('message', 'All Rooms are booked or are not available for the days.');
            result.put('status', 'cancelled');
        }
        return JSON.serialize(result);
    }
}