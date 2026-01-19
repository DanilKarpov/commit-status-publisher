<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>

<c:set var="address" value="${healthStatusItem.additionalData['address']}"/>
<c:set var="type" value="${healthStatusItem.additionalData['type']}"/>
<c:set var="serverVersion" value="${healthStatusItem.additionalData['serverVersion']}"/>
<c:set var="proxyVersion" value="${healthStatusItem.additionalData['version']}"/>

<c:choose>
  <c:when test="${healthStatusItem.category.id eq 'proxy_version_mismatch'}">
    Proxy server of type <code><c:out value="${type}"/></code> at <c:out value="${address}"/> has a newer version (<code><c:out value="${proxyVersion}"/></code>) of its configuration than the current TeamCity server (<code><c:out value="${serverVersion}"/></code>).
    To ensure compatibility between the servers, consider downgrading the proxy. <bs:help file="Multinode+Setup#Matching+Proxy+Version+with+Server"/>
  </c:when>
  <c:when test="${healthStatusItem.category.id eq 'proxy_version_obsolete'}">
    Proxy server of type <code><c:out value="${type}"/></code> at <c:out value="${address}"/> has an obsolete version (<code><c:out value="${proxyVersion}"/></code>) of its configuration.
    Please review the recommended <bs:helpLink file="Multinode+Setup" anchor="ProxyConfiguration">proxy server configuration</bs:helpLink>.
  </c:when>
</c:choose>

