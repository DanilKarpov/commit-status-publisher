<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@ taglib prefix="C" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<jsp:useBean id="filteredItemsCount" type="java.lang.Integer" scope="request"/>
<jsp:useBean id="duplicateRoots" type="java.util.Collection" scope="request"/>
<jsp:useBean id="duplicateInstances" type="java.util.Collection" scope="request"/>

<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<jsp:useBean id="healthStatusReportUrl" type="java.lang.String" scope="request"/>

<c:set var="inplaceMode" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>
<c:set var="cameFromUrl" value="${showMode eq inplaceMode ? pageUrl : healthStatusReportUrl}"/>

<script type="text/javascript">
  BS.RedundantVcsRootsReport = {
    toggleDivsVisibility: function (divToShow, divToHide){
      $(divToShow).style.display = "block";
      $(divToHide).style.display = "none";
    }
  }
</script>

<c:choose>
  <c:when test="${not empty duplicateRoots}">
    Following VCS roots have similar settings and could be merged:
    <ul>
      <c:forEach items="${duplicateRoots}" var="duplicateRoot">
        <c:set var="vcsRoot" value="${duplicateRoot}"/>
        <c:set var="project" value="${vcsRoot.project}"/>
        <li>
          <admin:vcsRootName vcsRoot="${vcsRoot}" editingScope="" cameFromUrl="${cameFromUrl}"/>
          defined in project <admin:editProjectLink projectId="${project.externalId}"><c:out value="${project.fullName}"/></admin:editProjectLink>
        </li>
      </c:forEach>
      <c:if test="${filteredItemsCount > 0}">
        <li>
          and <b>${filteredItemsCount}</b> inaccessible VCS root<bs:s val="${filteredItemsCount}" />
        </li>
      </c:if>
    </ul>
  </c:when>
  <c:when test="${not empty duplicateInstances}">
    Following VCS root usages are identical:
    <ul>
      <c:forEach items="${duplicateInstances}" var="rootInstanceGroup">
        <c:set var="identity" value="${util:forJSIdentifier(rootInstanceGroup.identity)}"/>
        <c:set var="root" value="${rootInstanceGroup.parentRoot}"/>
        <c:set var="accessibleBuildTypes" value="${rootInstanceGroup.buildTypes}"/>
        <c:set var="moreBuildTypes" value="${rootInstanceGroup.moreBuildTypes}"/>
        <c:set var="moreBuildTypesCount" value="${fn:length(moreBuildTypes)}"/>
        <c:set var="filteredBuildTypesCount" value="${rootInstanceGroup.filteredBuildTypesCount}"/>
        <li>
          <admin:vcsRootName vcsRoot="${root}" editingScope="" cameFromUrl="${cameFromUrl}"/>
          attached to
          <ul>
            <c:forEach items="${accessibleBuildTypes}" var="buildType">
              <li>
                <admin:editBuildTypeLinkFull buildType="${buildType}" cameFromUrl="${cameFromUrl}"/>
              </li>
            </c:forEach>
            <c:choose>
              <c:when test="${moreBuildTypesCount > 0}">
                <c:set var="shortMoreDivId" value="shortMoreBuildTypesSection_${identity}"/>
                <c:set var="fullMoreDivId" value="fullMoreBuildTypesSection_${identity}"/>
                <div id="${shortMoreDivId}">
                  and <b>${moreBuildTypesCount}</b>  build configuration<bs:s val="${moreBuildTypesCount}"/> <a href="#" onclick="BS.RedundantVcsRootsReport.toggleDivsVisibility('${fullMoreDivId}', '${shortMoreDivId}'); return false;">more</a>
                </div>
                <div id="${fullMoreDivId}" style="display: none">
                  <c:forEach items="${moreBuildTypes}" var="buildType">
                    <li>
                      <admin:editBuildTypeLinkFull buildType="${buildType}" cameFromUrl="${cameFromUrl}"/>
                    </li>
                  </c:forEach>
                  <c:if test="${filteredBuildTypesCount > 0}">
                    <li>
                      <c:if test="${not empty accessibleBuildTypes}">and</c:if> <b>${filteredBuildTypesCount}</b> inaccessible build configuration<bs:s val="${filteredBuildTypesCount}" />
                    </li>
                  </c:if>
                </div>
              </c:when>
              <c:otherwise>
                <c:if test="${filteredBuildTypesCount > 0}">
                  <li>
                    <c:if test="${not empty accessibleBuildTypes}">and</c:if> <b>${filteredBuildTypesCount}</b> inaccessible build configuration<bs:s val="${filteredBuildTypesCount}" />
                  </li>
                </c:if>
              </c:otherwise>
            </c:choose>
          </ul>
        </li>
        <c:if test="${filteredItemsCount > 0}">
          <li>
            and usages of <b>${filteredItemsCount}</b> inaccessible VCS root<bs:s val="${filteredItemsCount}" />
          </li>
        </c:if>
      </c:forEach>
    </ul>
  </c:when>
</c:choose>
