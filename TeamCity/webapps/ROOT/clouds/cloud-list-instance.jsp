<%@include file="/include-internal.jsp" %>
<%@ taglib prefix="clouds" tagdir="/WEB-INF/tags/clouds" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<jsp:useBean id="profileInfo" scope="request" type="jetbrains.buildServer.clouds.server.web.beans.CloudTabFormProfileInfo"/>
<jsp:useBean id="image" scope="request" type="jetbrains.buildServer.clouds.server.web.beans.CloudTabFormImageInfo"/>
<jsp:useBean id="instance" scope="request" type="jetbrains.buildServer.clouds.server.web.beans.CloudTabFormInstanceInfo"/>


<tr class="instance">
  <td class="noRightBorder instanceName <c:if test="${not instance.canManuallyTerminate}">instanceNameGrayed</c:if>">
    <span class="instanceLaunchedTime">Launched <bs:date value="${instance.instance.startedTime}"
    /></span>
    <c:if test="${not instance.hasError}">
      <clouds:imageState status="${instance.instance.status}" hasRunningBuild="${instance.runningBuild}"/>
    </c:if>
    <c:if test="${(instance.agent eq null)}">
      <c:out value="${instance.name}"/>
    </c:if>
    <bs:agentDetailsFullLink agent="${instance.agent}" doNotShowOSIcon="${true}" doNotShowPoolInfo="${true}" showRunningStatus="${instance.expired}"  useDisplayName="${true}"/>
    <c:if test="${not instance.runningBuild and instance.canManuallyTerminate}"
    > (idle<c:if test="${instance.idleMinutes > 0}"> for <c:out value="${instance.idleMinutes}"/> minutes</c:if>)</c:if
    ><clouds:cloudProblemsLink controlId="error_${instance.id}" problems="${instance.problems}">
      Instance Error
    </clouds:cloudProblemsLink>
    <clouds:cloudProblemContent controlId="error_${instance.id}" problems="${instance.problems}"/>
    <c:if test="${instance.expired and instance.canManuallyTerminate}"><c:if test="${instance.agent.runningBuild != null}"
    >will be stopped after current build finishes</c:if
    ><c:if test="${instance.agent.runningBuild == null}">will be stopped soon</c:if></c:if>
  </td>
  <td class="buttons">
    <c:set var="showInstanceStatus" value="${true}"/>
    <c:set var="canStart" scope="request" value="${param.userCanStart}"/>
    <c:if test="${canStart=='true'}">
      <c:if test="${instance.canManuallyTerminate}">
        <c:set var="showInstanceStatus" value="${false}"/>
        <c:set var="stopInstanceId"><bs:escapeForJs text="${instance.uniqueId}" forHTMLAttribute="true"/></c:set>

        <div id="stopInstanceDiv_${stopInstanceId}">
          <a href="#" onclick="BS.Clouds.stopInstance('${stopInstanceId}','<bs:escapeForJs text="${profileInfo.project.projectId}"/>','<bs:escapeForJs
              text="${profileInfo.id}"/>','<bs:escapeForJs forHTMLAttribute="true" text="${image.id}"/>','<bs:escapeForJs forHTMLAttribute="true" text="${instance.id}"/>',<bs:escapeForJs
              text="${instance.expired}"/>); return false;">
            <c:if test="${instance.expired}">Force </c:if>Stop
          </a>
        </div>
        <div id="stoppingInstanceDiv_${stopInstanceId}" style="display:none;">
          <forms:saving className="progressRingInline"/> Stopping...
        </div>
      </c:if>
    </c:if>
    <c:if test="${showInstanceStatus}">
      <c:out value="${instance.statusText}"/>
    </c:if>
  </td>
</tr>