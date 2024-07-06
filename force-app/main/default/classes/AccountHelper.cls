/*
AccountHelper Overview

The `AccountHelper` class is designed to provide helper methods that assist in performing specific 
operations on Account records. 
This class is intended to modularize the logic used in the `AccountTrigger` to ensure separation of 
concerns, improve readability, and ease maintenance. 

This class is currently stubbed out. As part of this exercise, you are expected to:
1. Implement the method bodies to carry out the specified operations on Account records.
2. Refactor the `AccountTrigger` to utilize the methods provided in this `AccountHelper` class.

Methods:
- `setTypeProspect(SObject objects)`: 
    - Purpose: Update the 'Type' field of the given Account record to 'Prospect' if it's not already set.
    - Note: You'll likely need to adjust the method signature to accept the necessary parameters.

- `addressCopy()`: 
    - Purpose: Copy the shipping address of the Account to its billing address. 
    - Note: You'll likely need to adjust the method signature to accept the necessary parameters.

- `setRating`: 
    - Purpose: Evaluate certain conditions on the Account and assign a rating based on that evaluation. 
    You'll need to define the method's signature and implement its logic.

- `defaultContact`: 
    - Purpose: Create a default contact related to the Account after the Account is inserted. You'll 
    need to define the method's signature and implement its logic.

Remember:
Always ensure that your helper methods are bulk-safe to handle multiple records efficiently. 
*/
public with sharing class AccountHelper {
  // method called with Before Insert trigger that
  // sets Account Type to "Prospect" if it is null
  public void setTypeProspect(List<Account> acctLst) {
    for (Account acc : acctLst) {
      if (acc.Type == null) {
        acc.Type = 'Prospect';
      }
    }
  }

  // method called with Before Insert trigger that
  // copies the Account Shipping Address to the
  // Billing Address
  public void copyAddress(List<Account> acctLst) {
    for (Account acc : acctLst) {
      if (acc.ShippingStreet != null) {
        acc.BillingStreet = acc.ShippingStreet;
      }

      if (acc.ShippingCity != null) {
        acc.BillingCity = acc.ShippingCity;
      }

      if (acc.ShippingState != null) {
        acc.BillingState = acc.ShippingState;
      }

      if (acc.ShippingPostalCode != null) {
        acc.BillingPostalCode = acc.ShippingPostalCode;
      }

      if (acc.ShippingCountry != null) {
        acc.BillingCountry = acc.ShippingCountry;
      }
    }
  }

  // method called with Before Insert trigger that
  // sets the Account Rating to "Hot" if certain
  // fields are filled in
  public void setRating(List<Account> acctLst) {
    for (Account acc : acctLst) {
      if (acc.Phone != null && acc.Website != null && acc.Fax != null) {
        acc.Rating = 'Hot';
      }
    }
  }

  // method called with After Insert trigger that creates
  // a default Contact for the account
  public void setDefaultContact(Map<Id, Account> acctMap) {
    List<Contact> contacts = new List<Contact>();
    for (Account acc : acctMap.values()) {
      Contact con = new Contact();
      con.LastName = 'DefaultContact';
      con.Email = 'default@email.com';
      con.AccountId = acc.Id;
      contacts.add(con);
    }
    insert as user contacts;
  }
}
