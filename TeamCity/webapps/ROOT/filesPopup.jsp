<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="modificationFilesBean" type="jetbrains.buildServer.controllers.changes.ModificationFilesBean" scope="request"/>

<div class="filesPopupHeader clearfix">
  <div class="filesPopupHeaderActions">
    <c:set var="showType" value="compact" scope="request"/>
    <ext:includeExtensions placeId="<%=PlaceId.CHANGE_DETAILS_BLOCK%>"/>
  </div>

  <div class="filesPopupHeaderTitle">
    <bs:trim maxlength="100">${
    modificationFilesBean.modification.personal
      ? modificationFilesBean.modification.personalChangeInfo.commitType.name
      : modificationFilesBean.modification.vcsRoot.name
        }</bs:trim>: <span class="revisionNum"><bs:shortRevision change="${modificationFilesBean.modification}"/></span>
  </div>
</div>
<bs:changedFiles changes="${modificationFilesBean.changesToShow}"
                 modification="${modificationFilesBean.modification}"
                 maxFilePathLen="80"
                 openLinkInSameTab="${modificationFilesBean.openFileLinksInSameTab}"
                 highlightChange="${modificationFilesBean.highlightChange}"/>
<div class="filesPopupFooter">
<bs:modificationLink modification="${modificationFilesBean.modification}"
                     buildTypeId="${modificationFilesBean.buildTypeId}"
                     tab="vcsModificationFiles">View change details
  <c:if test="${modificationFilesBean.showAllFilesLink}">
    (all files)
  </c:if> &raquo;
</bs:modificationLink>
</div>
