<%@include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<jsp:useBean id="project" scope="request" type="jetbrains.buildServer.serverSide.SProject"/>
<div>
  Could not decrypt some of the secure values (passwords, API tokens, etc) while loading settings of the project <admin:editProjectLinkFull project="${project}"/>:
</div>
<ul>
  <c:forEach items="${healthStatusItem.additionalData['brokenTokens']}" var="tinfo">
    <li>
      <c:out value="${tinfo.value}"/>
    </li>
  </c:forEach>
  <admin:editProjectLink projectId="${project.externalId}" addToUrl="&tab=versionedSettings&subTab=tokens">Provide missing secure values</admin:editProjectLink>
</ul>

