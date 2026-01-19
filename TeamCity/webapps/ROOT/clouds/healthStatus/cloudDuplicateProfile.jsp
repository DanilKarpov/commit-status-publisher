<%@ page import="jetbrains.buildServer.serverSide.healthStatus.ItemSeverity" %>
<%@ page import="jetbrains.buildServer.clouds.server.serverHealth.DuplicateCloudProfileHealthReport" %>
<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>

<c:set var="isSeverityInfo" value='<%=healthStatusItem.getSeverity()==ItemSeverity.INFO%>'/>
<c:set var="brokenProfiles" value='<%=healthStatusItem.getAdditionalData().get(DuplicateCloudProfileHealthReport.CLOUD_PROFILES_KEY)%>'/>


  <c:if test="${not empty brokenProfiles}">
    The following cloud profiles use non-unique IDs:
    <c:forEach items="${brokenProfiles}" var="duplicate">
      <c:choose>
        <c:when test="${not empty duplicate.otherProject}">
          <c:out value="${duplicate.currentProjectProfile.profileId}"/> in cloud profile <c:out value="${duplicate.currentProjectProfile.profileName}"/> is also being used in project <bs:projectLink project="${duplicate.otherProject}" />
        </c:when>
        <c:otherwise>
          <c:out value="${duplicate.currentProjectProfile.profileId}"/> in cloud profile <c:out value="${duplicate.currentProjectProfile.profileName}"/> />
        </c:otherwise>
      </c:choose>
    </c:forEach>

    <br/>

    Utilizing multiple cloud profiles with identical IDs may result in unexpected behavior. It is advisable to assign unique identifiers to each cloud profile.
  </c:if>
