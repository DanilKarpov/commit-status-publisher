<%@ page import="jetbrains.buildServer.serverSide.healthStatus.ItemSeverity" %>
<%@ page import="jetbrains.buildServer.clouds.server.serverHealth.CloudProfileValidationHealthReport" %>
<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>

<c:set var="isSeverityInfo" value='<%=healthStatusItem.getSeverity()==ItemSeverity.INFO%>'/>
<c:set var="brokenProfiles" value='<%=healthStatusItem.getAdditionalData().get(CloudProfileValidationHealthReport.CLOUD_PROFILES_KEY)%>'/>


  <c:if test="${not empty brokenProfiles}">
    Project has cloud profiles with invalid data. The following cloud profiles do not meet data validation requirements:<br>
    <br>
    <c:forEach items="${brokenProfiles}" var="validatedProfile">
      <b><c:out value="${validatedProfile.currentProjectProfile.profileName}"/>:</b>
      <ul>
        <c:forEach items="${validatedProfile.validationData}" var="validationData">
          <li><c:out value="${validationData}"/></li>
        </c:forEach>
      </ul>
    </c:forEach>
  </c:if>
