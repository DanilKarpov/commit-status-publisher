<%@include file="/include-internal.jsp" %>
<%@ taglib prefix="ext" tagdir="/WEB-INF/tags/ext" %>
<%@ taglib prefix="ring" tagdir="/WEB-INF/tags/ring" %>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>

<h2 class="noBorder">Versioned Settings</h2>

<bs:linkCSS>
  /css/pager.css
  /css/filePopup.css
</bs:linkCSS>
<style>
  .versionedSettingsTabs {
    margin-top: 8px;
  }

  .versionedSettingsTabs a:not(:first-child) {
    margin-left: -4px !important;
  }
</style>
<c:set var="subTab"><c:out value="${param['subTab']}"/></c:set>
<c:url value='/admin/editProject.html?projectId=${project.externalId}&tab=versionedSettings&subTab=${subTab}' var="refreshUrl"/>
<bs:refreshable containerId="versionedSettingsTabs" pageUrl="${refreshUrl}">
  <c:if test="${tabs.size() > 1}">
    <div class="versionedSettingsTabs">
      <ring:buttonGroup className="ring-button-group-buttonGroup">
        <c:forEach var="tab" items="${tabs}">
          <a class="ring-button-button ring-button-block  ring-button-heightM ${tab.selected ? 'ring-button-active' : ''}" href="<c:url value="${basePageUrl}&subTab=${tab.id}"/>">
              ${tab.title}
            <c:if test="${tab.titleHasWarning}">
              <i class="tc-icon icon16 tc-icon_attention tc-icon_attention_yellow" style="margin-left: 2px; margin-right: -6px;"></i>
            </c:if>
          </a>
        </c:forEach>
      </ring:buttonGroup>
    </div>
  </c:if>

  <jsp:include page="${selectedTab.contentUrl}"/>

</bs:refreshable>
