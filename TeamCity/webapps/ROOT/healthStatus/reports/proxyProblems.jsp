<%@ include file="/include-internal.jsp" %>

Requests with incorrect HTTP proxy configuration are detected.<br/>

<%--@elvariable id="problems" type="java.util.Map"--%>
<c:forEach items="${problems}" var="problemEntry">
  <c:set var="problemType" value="${problemEntry.key}"/>
  <c:set var="problems" value="${problemEntry.value}"/>
  <%--@elvariable id="problemDescr" type="java.lang.String"--%>
  <%--@elvariable id="problems" type="java.util.List"--%>
  <div style="margin-top: 1em;">
    <c:out value="${problemType}"/>:
    <ul>
      <c:forEach items="${problems}" var="problem">
        <%--@elvariable id="problem" type="jetbrains.buildServer.web.proxyProblems.ProxyServerConfigurationCheckController.Problem"--%>
        <li>Request by <bs:userName server="${serverTC}" userId="${problem.affectedUser.id}"/> from ${problem.remoteAddr}</li>
      </c:forEach>
    </ul>
  </div>
</c:forEach>

<div style="margin-top: 1em;">
  <c:url var="proxyCheckUrl" value="/proxyCheck.html"/>
  <c:url var="logLink" value="/admin/admin.html?item=diagnostics&tab=logs&file=teamcity-server.log"/>
  See <a href="${logLink}">teamcity-server.log</a> for details. <br/>
  <a href="${proxyCheckUrl}" target="_blank" rel="noreferrer">Current session proxy diagnostics</a>.
</div>

