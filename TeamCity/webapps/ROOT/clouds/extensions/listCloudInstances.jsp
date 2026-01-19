<%--
  Created by IntelliJ IDEA.
  User: sergeypak
  Date: 09/11/2017
  Time: 15:36
  To change this template use File | Settings | File Templates.
--%>
<%@include file="/include-internal.jsp" %>

<jsp:useBean id="imageId" scope="request" type="java.lang.String"/>

<c:if test="${imageId != ''}" >
  <script type="text/javascript">
    BS.Clouds.Admin.registerRefresh();
  </script>

  <jsp:useBean id="image" scope="request" type="jetbrains.buildServer.clouds.server.web.beans.CloudTabFormImageInfo"/>
  <jsp:useBean id="profileInfo" scope="request" type="jetbrains.buildServer.clouds.server.web.beans.CloudTabFormProfileInfo"/>
  <authz:authorize allPermissions="VIEW_AGENT_CLOUDS" projectId="${profileInfo.project.projectId}">
    <div id="agentTypeInstances" class="inlined" style="margin: 0; padding: 0">
      <h2>Running Instances</h2>
      <bs:refreshable containerId="cloudRefreshable" pageUrl="${pageUrl}">
        <jsp:include page="../cloud-list-image.jsp"/>
      </bs:refreshable>
    </div>
    <script>
    $j(document).ready(function(){
      $j('#agentTypeInstances').prependTo('#agentTypeSummary #extras');
    });
  </script>
</authz:authorize>
</c:if>