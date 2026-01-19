<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>

<c:set var="agents" value="${healthStatusItem.additionalData['agents']}"/>
<c:set var="agentsCount" value="${healthStatusItem.additionalData['agentsCount']}"/>

Build agents don't use HTTP proxy.
<p>In a high-availability TeamCity installation, all build agents need to connect to a reverse HTTP proxy � not to the main node. Please set the proxy URL as <code>`serverUrl`</code> in all build agents' configuration files.
  <bs:help file="Multinode+Setup#Proxy+Configuration"/>
</p>


<bs:agentsGroupedByPool containerId="noProxyMultiNode"
                        agentsGroupedByPools="${agents}"
                        hasSeveralPools="${healthStatusItem.additionalData['hasSeveralPools']}">
  <jsp:attribute name="agentListHeader">
    The following <bs:plural txt="agent" val="${agentsCount}"/> need<c:if test="${agentsCount == 1}"><bs:out value="s"/></c:if> to be reconfigured:
  </jsp:attribute>
</bs:agentsGroupedByPool>
