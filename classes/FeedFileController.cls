/* Class:       FeedFileController
 * Created On:  8/10/2016
 * Created by:  OpFocus Team
 * Description: Controller for any page that performs special handling when 
 * 		a FeedItem of type File is added. We assign a Topic to it
 *		so we can search for it and filter our Files by Topic name.
 *
 * @see Feed VF page
 * @see ListFeedFiles VF page
 */ 
public with sharing class FeedFileController {
	
	public Id ourId {get; set;}
	public String topic {get; set;}

	public static final String FILE_FEED_TYPE = 'ContentPost';

	private String feedPage;
	private String ourObjHomePage;
	
	public FeedFileController(ApexPages.StandardController ctrl) {
		ourId = ctrl.getRecord().Id;
		init();
	}	

	public FeedFileController() {	
		ourId = ApexPages.currentPage().getParameters().get('id');
		init();
	}

	private void init() {
		topic = ApexPages.currentPage().getParameters().get('topic');
		System.debug('========> ourId = ' + ourId + ', and topic = ' + topic);
		feedPage = '/apex/Feed?id=' + ourId + '&topic=' + topic;
		ourObjHomePage = '/' + ourId;
	}

	/**  
     * Redirect user to Feed page where they can upload a file
     * that will automatically get tagged with our API Topic. 
	 */
	public PageReference goToFeedPage() {
		return new PageReference(feedPage);
	}

	public PageReference goToObjectHome() {
		return new PageReference(ourObjHomePage);
	}

	/**
	 * When User uploads a new File to the Feed, we want to set the
	 * Topic on this File so that we can display it later in the
	 * Add Chipset Parts or Configuration and Maintenance pages
	 * We only set the Topic for Files uploaded via our button.
	 */
	public PageReference setTopic() {
		try {
			System.debug('======> setTopic for object id ' + ourId);
			FeedItem feedItem = [select CreatedDate,Id,ParentId,RelatedRecordId,Title,Type 
				from FeedItem where Type=:FILE_FEED_TYPE and ParentId=:ourId 
				order by CreatedDate DESC limit 1];
			System.debug('==========> feedItem = ' + feedItem);

			// adding topic to FeedItem just created
			List<ConnectApi.Topic> ourTopics = ConnectApi.Topics.getTopics(null, topic, true).topics;
			ConnectApi.Topic ourTopic;
			// if this is our first file to be associated with our Topic, create Topic now.
			if (ourTopics.isEmpty()) {
				System.debug('=======> Creating Topic ' + topic);
				ourTopic = ConnectApi.Topics.createTopic(null, topic, topic + ' for Sobject Id ' + ourId);
			} else {
				ourTopic = ourTopics.get(0);
			}

			ConnectApi.Topics.assignTopic(null, feedItem.Id, ourTopic.Id);
			return new PageReference(ourObjHomePage);			
		}
		catch(Exception exc) {
			String errorMsg = 'There was an error processing your request. Exception Cause = ' + 
				exc.getCause() + '; Message = ' + exc.getMessage();
			System.debug('========> ' + errorMsg + ', Stack Trace = ' + 
				exc.getStackTraceString());
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,
				errorMsg);
            ApexPages.addMessage(myMsg);
			return null;
		}
	}

	/**
	 * Return list of FeedItem(s) that were attached to this object via
	 * a button Attach File button. 
	 */
	public List<FeedItem> getFiles() {
		try {
			List<FeedItem> files = new List<FeedItem>();
			for (FeedItem feedItem : [select CreatedDate, CreatedBy.Name, CreatedById, Id, ParentId, RelatedRecordId, Title, Type 
				from FeedItem where HasContent=true and Type=:FILE_FEED_TYPE and ParentId=:ourId 
				order by CreatedDate DESC]) {
				// Filter to only show Feed Items with our API Topic
				System.debug('========> ConnectApi.Topics.getTopics(null, feedItem.Id).topics = ' + 
					JSON.serializePretty(ConnectApi.Topics.getTopics(null, feedItem.Id).topics));
				for (ConnectApi.Topic thisTopic : ConnectApi.Topics.getTopics(null, feedItem.Id).topics) {
					System.debug('========> thisTopic.name = ' + thisTopic.name);
					if (thisTopic.name.equals(topic)) {
						files.add(feedItem);
						break;
					}
				}
			}
			return files;
		} catch (Exception exc) {
			String errorMsg = 'There was an error processing your request. Exception Cause = ' + 
				exc.getCause() + '; Message = ' + exc.getMessage();
			System.debug('========> ' + errorMsg + ', Stack Trace = ' + 
				exc.getStackTraceString());
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,
				errorMsg);
            ApexPages.addMessage(myMsg);
			return null;
		}
	}
}