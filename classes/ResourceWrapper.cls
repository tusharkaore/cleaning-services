/**
* @description Wrapper class to hold the Resource record data  
* @className ResourceWrapper
* @author Tushar Kaore
* @lastModified 24/01/2022
*/

public class ResourceWrapper {

    public String Id;
    public Boolean IsActive;
    public String Name;
    public String RelatedRecordId;
    public String ResourceType;

    //Method to conver JSON to Array of objects
    public static List<ResourceWrapper> getList(String json) {
        return (List<ResourceWrapper>) System.JSON.deserialize(json, List<ResourceWrapper>.class);
    }
}