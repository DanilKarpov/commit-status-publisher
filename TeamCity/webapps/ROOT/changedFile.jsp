<%@ include file="/include-internal.jsp"%><%@
    taglib prefix="intprop" uri="/WEB-INF/functions/intprop"%><%@
    page import="jetbrains.buildServer.vcs.VcsChangeInfo" %><%@
    page import="jetbrains.buildServer.web.functions.auth.AuthorizationFunctions" %><%@
    page import="jetbrains.buildServer.web.openapi.PlaceId"

%><jsp:useBean id="modification" scope="request" type="jetbrains.buildServer.vcs.SVcsModification"
/><jsp:useBean id="changedFile" scope="request" type="jetbrains.buildServer.vcs.FilteredVcsChange"
/><c:set var="maxFilePathLen" value="${empty maxFilePathLen ? 100000 : maxFilePathLen}"
/><%
  boolean hasPermissionToViewFileContent = AuthorizationFunctions.hasFileContentAccess(modification);
  VcsChangeInfo.Type type = changedFile.getType();
  String typeDescription = type.getDescription();
  String shownTypeDescription = typeDescription.replace("directory", "");
  boolean showChangeTypeDetails = !typeDescription.equals(changedFile.getChangeTypeName());
  boolean showDiffLink = hasPermissionToViewFileContent && !type.isDirectory() && type != VcsChangeInfo.Type.NOT_CHANGED;
  boolean showOpenInIDELink = !type.isDirectory();
  pageContext.setAttribute("hasContentPermission", hasPermissionToViewFileContent);
  pageContext.setAttribute("showDiffLink", showDiffLink);
  pageContext.setAttribute("showOpenInIDELink", showOpenInIDELink);
  pageContext.setAttribute("shownTypeDescription", shownTypeDescription);
  pageContext.setAttribute("showChangeTypeDetails", showChangeTypeDetails);
%><c:set var="fullChangePathTitle"><c:if test="${hasContentPermission}"><c:out value="${changedFile.fileName}"/></c:if></c:set
><c:set var="changePath"><c:choose
    ><c:when test="${not empty changedFile.relativeFileName}">${changedFile.relativeFileName}</c:when
    ><c:otherwise>[Project Root]</c:otherwise
    ></c:choose
    ><c:if test="${changedFile.type.directory}"> (directory)</c:if></c:set><c:set var="changePath"><bs:trimWithTooltip maxlength="${maxFilePathLen}" trimCenter="true"
explicitTooltipText="${fullChangePathTitle}">${changePath}</bs:trimWithTooltip></c:set>
<tr <c:if test="${not empty highlight and highlight}">style="background: #FFFAB4;"</c:if>>
  <td class="typeTD"><span class="changeType ${changedFile.type.description}"><c:out value="${shownTypeDescription}"/></span><c:if test="${showChangeTypeDetails}"><bs:commentIcon text="${changedFile.changeTypeName}"/></c:if></td>
  <td class="fileTD ${changedFile.type.description}" title="${fullChangePathTitle}">
    <c:choose
    ><c:when test="${showDiffLink}"
        ><c:url value='${intprop:getBoolean("teamcity.diffView.codeMirrorUI") ? "/diff.html" : "/diffView.html"}' var="diffUrl"
          ><c:param name="id" value="${modification.id}"
          /><c:param name="vcsFileName" value="${changedFile.fileName}"
          /><c:param name="personal" value="${modification.personal}"
          /></c:url><a href="${diffUrl}" <c:if test="${empty openLinkInSameTab or not openLinkInSameTab}">target="_blank" rel="noreferrer"</c:if>>${changePath}</a></c:when
    ><c:otherwise>${changePath}</c:otherwise
    ></c:choose
    ><c:if test="${not empty changedFile.afterChangeRevisionNumber and changedFile.afterChangeRevisionNumber != modification.displayVersion and changedFile.afterChangeRevisionNumber != modification.version}"
    ><span class="revision"> (rev. <c:out value="${changedFile.afterChangeRevisionNumber}"/>)</span
    ></c:if
    ><c:if test="${changedFile.excluded}"
    ><span class="excluded"> (<c:out value="${changedFile.excludeReason}"/>)</span
    ></c:if
    ><c:if test="${showOpenInIDELink}"
    ><span class="ide_link_group"><bs:activateFileLink fileName="${changedFile.relativeFileName}" projectName="${projectName}"/></span
    ><ext:includeExtensions placeId="<%=PlaceId.CHANGED_FILE_LINK%>"/></c:if>
  </td>
</tr>
