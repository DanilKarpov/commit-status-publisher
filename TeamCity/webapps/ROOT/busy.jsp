<%@ include file="/include-internal.jsp"%>
<c:set var="pageTitle" value="Cleanup in progress" scope="request"/>
<jsp:useBean id="cleanupDetails" scope="request" type="jetbrains.buildServer.serverSide.cleanup.CleanupProcessState"/>
<!DOCTYPE html>
<html>
<head>
  <title><c:if test="${not empty pageTitle}">${pageTitle} &mdash; </c:if>TeamCity</title>
  <bs:linkCSS>
    /css/FontAwesome/css/font-awesome.min.css
    /css/main.css
    /css/icons.css
  </bs:linkCSS>

  <script type="text/javascript">
    var base_uri=window.location.protocol+"//"+window.location.host+"<%=request.getContextPath() %>";
  </script>

  <bs:linkScript>
    /js/ring/jquery.js
    /js/ring/jquery-migrate.min.js
    /js/jquery/jquery.z-index.js
  </bs:linkScript>

  <script type="text/javascript">
    window.$j = jQuery.noConflict();
  </script>

  <bs:predefinedIntProps/>

  <bs:prototype/>
  <bs:linkScript>
    /js/ring/underscore.js

    /js/bs/bs.js
    /js/bs/cookie.js
    /js/bs/position.js
    /js/bs/basePopup.js
    /js/bs/menuList.js
    /js/bs/forms.js
    /js/bs/jvmStatusForm.js
    /js/bs/cleanupPolicies.js
  </bs:linkScript>

  <style type="text/css">
    .maintenanceMessage {
      font-size: 140%;
      margin-top: 10em;
      margin-left: auto;
      margin-right: auto;
      width: 80%;
    }

    .cleanupDiagnostics {
      font-size: 100%;
      margin-top: 10em;
      margin-left: auto;
      margin-right: auto;
      width: 80%;
    }
  </style>
  <script type="text/javascript">
    $j(document).ready(function() {
      window.setTimeout(function() {
        var href = document.location.href;
        if (href.indexOf('?') == -1) {
          if (href.indexOf('#') != -1) {
            document.location.href = href.replace('#', '?_#');
          } else {
            document.location.href = href + '?_';
          }
        } else {
          BS.reload(true);
        }
      }, 15000);
    })
  </script>
  <link rel="Shortcut Icon" href="<c:url value="/img/icons/favicon.ico"/>" type="image/x-icon"/>
</head>

<body>

<div class="maintenanceMessage">
  The server is performing clean-up at the moment. Unfortunately, you're using the internal HSQL database, and it requires a global server lock.
  To avoid the lock, please <bs:helpLink file="Migrating+to+External+Database">migrate</bs:helpLink> to one of the supported external databases.
  <br/>
  <br/>
  The cleanup may take from several minutes to several hours depending on the size of the database.
  <br/>
  <br/>
  Elapsed time: <bs:printTime time="${cleanupDetails.elapsedTime / 1000}" showIfNotPositiveTime="&lt; 1s"/>
  <c:if test="${cleanupDetails.processedBuilds == 0}">(0% builds processed)</c:if>
  <c:if test="${cleanupDetails.processedBuilds > 0}">(<bs:percent value="${cleanupDetails.processedBuilds}" total="${cleanupDetails.buildsToProcess}" fractionDigits="1"/> builds processed)</c:if>
  <br/>
  <br/>
  Current stage: <c:out value="${cleanupDetails.currentStage}"/>

<c:if test="${afn:permissionGrantedGlobally('CONFIGURE_SERVER_DATA_CLEANUP') and not cleanupDetails.interrupted}">
  <form action="<c:url value='/admin/cleanupPolicies.html'/>" method="post" id="cleanupTimeForm" style="margin-top: 0.5em">
    <input class="btn" type="button" value="Stop clean-up" onclick="BS.CleanupPoliciesForm.submitStopCleanup()"/>
    <input type="hidden" name="cleanupPageAction" value="stopCleanup"/>
  </form>
</c:if>

<c:if test="${cleanupDetails.interrupted}">
  <div class="attentionComment" style="margin-top: 0.5em; font-size: 80%; width: 80%;"
    ><bs:buildStatusIcon type="red-sign" className="warningIcon"/>Clean-up process is stopping, please wait till clean-up finishes current tasks.</div>
</c:if>
  <br/>
  <br/>
  This page will be reloaded automatically when the clean-up process is completed.
</div>

<c:if test="${afn:permissionGrantedGlobally('CHANGE_SERVER_SETTINGS')}">
<div class="cleanupDiagnostics blockHeader">
  <h2>Cleanup Diagnostics</h2>

  <form action="<c:url value='/admin/diagnostic.html'/>" method="post" id="jvmStatusForm" style="padding:0; margin: 0.5em 0">
  <div style="width: 100%; margin-top: 0.5em;">
    <bs:messages key="threadDumpSucceeded"/>
  </div>

  <div>
    If clean-up process appears slow or is hanging, please try taking several thread dumps with some interval and send them to
    <bs:helpLink file='Reporting+Issues'>TeamCity developers</bs:helpLink>.
    <br/>
    <br/>
    <input class="btn" type="button" name="threadDump" value="Save Thread Dump" onclick="BS.JvmStatusForm.takeThreadDump()"/>
    <input type="hidden" name="actionName" value=""/>
  </div>
  </form>
</div>
</c:if>

<iframe style="height:0;width:0;visibility:hidden" src="about:blank">
  This frame should prevent back forward cache in Safari, see http://developer.apple.com/internet/safari/faq.html#anchor5
</iframe>
<div id="__tc_cleanupInProgressMarker"></div><!-- do not remove this div, it is used as marker to identify this page -->
</body>
</html>
