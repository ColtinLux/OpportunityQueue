global with sharing class SaveCalculation implements SBQQ.CalculateCallback {
    global void saveQuote(String quoteJSON){
        SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', quoteJSON);
    }
}