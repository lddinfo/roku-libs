'----------------------------------------------------------------
' GA Test Suite
'
' @return A configured TestSuite object.
'----------------------------------------------------------------
function TestSuite__GoogleAnalytics() as Object

    ' Inherite your test suite from BaseTestSuite
    this = BaseTestSuite()

    ' Test suite name for log statistics
    this.Name = "Google Analytics Library"

    this.SetUp = GoogleAnalyticsTestSuite__SetUp
    this.TearDown = GoogleAnalyticsTestSuite__TearDown

    ' Helper functions
    this.CreateMockServer = Helper__CreateMockServer
    this.HandleMockServerEvent = Helper__HandleMockServerEvent

    ' Add tests to suite's tests collection
    this.addTest("should create global object", TestCase__GoogleAnalytics_Global)
    this.addTest("should create object with expected functions", TestCase__GoogleAnalytics_Functions)
    this.addTest("should not send tracking data if tracking is not enabled", TestCase__GoogleAnalytics_NotTracking)
    this.addTest("init should set correct properties", TestCase__GoogleAnalytics_Init)
    this.addTest("should send correct track event request", TestCase__GoogleAnalytics_TrackEvent)
    this.addTest("should send correct track screen request", TestCase__GoogleAnalytics_TrackScreen)
    this.addTest("should send correct track transaction request", TestCase__GoogleAnalytics_TrackTransaction)
    this.addTest("should send correct track item request", TestCase__GoogleAnalytics_TrackItem)
    this.addTest("should cleanup requests", TestCase__GoogleAnalytics_CleanupRequests)

    return this
end function

sub GoogleAnalyticsTestSuite__SetUp()
    m.testObject = GoogleAnalyticsLib()
    ' Override default values for testing purposes
    m.testObject._clientID = "ce451d12-e1c2-4f6c-b74a-9ed4aeb66584"
    m.testObject._deviceModel = "1234X"
    m.testObject._deviceVersion = "3.2"
    m.testObject._appName = "AppName"
    m.testObject._appVersion = "1.2.3"
    m.testObject._ratio = "16-9"
    m.testObject._display = "1280x720"
    m.testObject._endpoint = "http://127.0.0.1:54321/"
    ' Mock server that will receive requests
    m.mockServer = m.CreateMockServer("127.0.0.1", 54321)
end sub

sub GoogleAnalyticsTestSuite__TearDown()
    m.mockServer.close()
    m.mockServer = invalid
    m.testObject = invalid
    m.delete("mockServer")
    m.delete("testObject")
    getGlobalAA().delete("analytics")
end sub

function TestCase__GoogleAnalytics_Global()
    return m.assertNotInvalid(getGlobalAA()["analytics"])
end function

function TestCase__GoogleAnalytics_Functions()
    expectedFunctions = ["init", "getPort", "trackEvent", "trackScreen", "trackTransaction", "trackItem"]
    return m.assertAAHasKeys(m.testObject, expectedFunctions)
end function

function TestCase__GoogleAnalytics_NotTracking()
    result = m.assertFalse(m.testObject._enabled)
    result += m.assertInvalid(m.testObject.trackEvent({category: "app", action: "test"}))
    result += m.assertInvalid(m.testObject.trackScreen({name: "testScreen"}))
    result += m.assertInvalid(m.testObject.trackTransaction({id: "1234", revenue: "12.34"}))
    result += m.assertInvalid(m.testObject.trackItem({transactionId: "1234", name: "dummy", price: "12.34", code: "TEST01", category: "test"}))
    return result
end function

function TestCase__GoogleAnalytics_Init()
    m.testObject.init("D-UMMY-ID")
    result = m.assertEqual(m.testObject._trackingID, "D-UMMY-ID")
    result += m.assertTrue(m.testObject._enabled)
    return result
end function

function TestCase__GoogleAnalytics_TrackEvent()
    m.testObject.init("D-UMMY-ID")
    m.testObject._sequence = 1
    m.testObject.trackEvent({ category: "app", action: "launch"})
    request = m.HandleMockServerEvent(m.mockServer)
    return m.assertEqual(request.data, "av=1.2.3&vp=16-9&ea=launch&v=1&tid=D-UMMY-ID&ec=app&cid=ce451d12-e1c2-4f6c-b74a-9ed4aeb66584&ds=app&sr=1280x720&an=AppName&t=event&z=1")
end function

function TestCase__GoogleAnalytics_TrackScreen()
    m.testObject.init("D-UMMY-ID")
    m.testObject._sequence = 1
    m.testObject.trackScreen({name: "testScreen"})
    request = m.HandleMockServerEvent(m.mockServer)
    return m.assertEqual(request.data, "av=1.2.3&cd=testScreen&vp=16-9&v=1&tid=D-UMMY-ID&cid=ce451d12-e1c2-4f6c-b74a-9ed4aeb66584&ds=app&sr=1280x720&an=AppName&t=screenview&z=1")
end function

function TestCase__GoogleAnalytics_TrackTransaction()
    m.testObject.init("D-UMMY-ID")
    m.testObject._sequence = 1
    m.testObject.trackTransaction({ id: "OD564", revenue: "10.00"})
    request = m.HandleMockServerEvent(m.mockServer)
    return m.assertEqual(request.data, "tr=10.00&v=1&tid=D-UMMY-ID&ti=OD564&ta=roku&cid=ce451d12-e1c2-4f6c-b74a-9ed4aeb66584&ds=app&t=transaction&z=1")
end function

function TestCase__GoogleAnalytics_TrackItem()
    m.testObject.init("D-UMMY-ID")
    m.testObject._sequence = 1
    m.testObject.trackItem({ transactionId: "OD564", name: "Test01", price: "10.00", code: "TEST001", category: "vod"})
    request = m.HandleMockServerEvent(m.mockServer)
    return m.assertEqual(request.data, "ip=10.00&v=1&tid=D-UMMY-ID&ti=OD564&iv=vod&in=Test01&cid=ce451d12-e1c2-4f6c-b74a-9ed4aeb66584&ds=app&t=item&ic=TEST001&z=1")
end function

function TestCase__GoogleAnalytics_CleanupRequests()
    m.testObject.init("D-UMMY-ID")
    m.testObject._sequence = 1
    m.testObject.trackScreen({name: "testScreen"})
    m.HandleMockServerEvent(m.mockServer)
    m.testObject._cleanupRequests()
    return m.assertEmpty(m.testObject._sentRequests)
end function
