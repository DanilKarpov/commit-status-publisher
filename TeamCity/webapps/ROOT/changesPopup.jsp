<%@ page import="jetbrains.buildServer.controllers.ActionMessages" %>
<%@ include file="include-internal.jsp" %>
<jsp:useBean id="sinceLastSuccessfulEnabled" scope="request" type="java.lang.Boolean"/>

<bs:messages key="buildNotFound"/>
<bs:messages key="buildTypeNotFound"/>
<c:set var="activeTab" value="thisBuild"/>
<c:if test="${not empty param['tab']}">
  <c:set var="activeTab" value="${util:escapeUrlForQuotes(param['tab'])}"/>
</c:if>

<c:if test='<%=!ActionMessages.getOrCreateMessages(request).hasMessage("buildNotFound") && !ActionMessages.getOrCreateMessages(request).hasMessage("buildTypeNotFound")%>'>
<c:if test="${sinceLastSuccessfulEnabled}">
  <div id="changesPopupTabs" class="simpleTabs"></div>
  <script type="text/javascript">
    (function() {
      var popupNavPane = new TabbedPane();
      popupNavPane.addTab("thisBuild", {
        caption: "In this build",
        onselect: function(tab) {
          BS.ChangesPopup.showCurrentBuild($('changesContainer'), ${currentPromotion.id});
          popupNavPane.setActiveCaption("thisBuild");
        }
      });
      popupNavPane.addTab("sinceSuccessful", {
        caption: "Since last successful build",
        onselect: function(tab) {
          BS.ChangesPopup.showSinceLastSuccessful($('changesContainer'), ${currentPromotion.id});
          popupNavPane.setActiveCaption("sinceSuccessful");
        }
      });
      popupNavPane.showIn('changesPopupTabs');
      if ("${activeTab}" == "thisBuild") {
        popupNavPane.setActiveCaption("${activeTab}");
      } else {
        popupNavPane.setActiveTab("${activeTab}");
      }
    })();
  </script>
</c:if>

<div class="changesContainer" id="changesContainer">
  <c:choose>
    <c:when test="${activeTab == 'sinceSuccessful' and not sinceLastSuccessfulEnabled}">
      <div>
        No changes in this build. <c:if test="${currentPromotion.associatedBuild != null}"><bs:_viewLog build="${currentPromotion.associatedBuild}" tab="buildChangesDiv">View source revisions</bs:_viewLog></c:if>
      </div>
    </c:when>
    <c:otherwise><jsp:include page="/changesPopupTab.html"/></c:otherwise>
  </c:choose>
</div>
</c:if>
