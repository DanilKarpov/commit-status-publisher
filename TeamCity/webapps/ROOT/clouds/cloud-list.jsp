<%@include file="/include-internal.jsp"%>
<%@ taglib prefix="clouds" tagdir="/WEB-INF/tags/clouds"  %>
<jsp:useBean id="form" type="jetbrains.buildServer.clouds.server.web.beans.CloudTabForm" scope="request"/>
<jsp:useBean id="pageUrl" scope="request" type="java.lang.String"/>

<script type="text/javascript">
  <%@include file="/js/bs/collapseExpand.js"%>
  BS.Clouds.Problems = {};
</script>

  <div class="cloud-profiles-header">
    <p class="_inline-block">
      <bs:collapseExpand collapseAction="BS.CollapsableBlocks.collapseAll(true, 'agentCloudProfileList'); return false"
                   expandAction="BS.CollapsableBlocks.expandAll(true, 'agentCloudProfileList'); return false">
      </bs:collapseExpand>
    </p>
    <p class="_inline-block">You have <strong>${fn:length(form.selfProfiles)}</strong> profile<bs:s val="${fn:length(form.selfProfiles)}"/> configured.</p>
  </div>
  <c:forEach items="${form.selfProfiles}" var="profileInfo">

    <clouds:cloudProblemContent controlId="error_${profileInfo.id}" problems="${profileInfo.problems}" />

    <p class="icon_before icon16 blockHeader profileHeader expanded" id="profile${profileInfo.id}">
      <clouds:profile profile="${profileInfo}" inlineDescription="true" hideEditLink="${not profileInfo.cloudTypeLoaded}"/>
    </p>

    <c:set var="cloudProfileId" value="Block_profile${profileInfo.id}"/>

    <div class="cloudProfile" id="cloudProfile:${profileInfo.id}" style="${util:blockHiddenCss(pageContext.request, cloudProfileId, false)}">
      <c:choose>
        <c:when test="${profileInfo.loading}">
          <forms:saving className="progressRingInline"/>&nbsp;Loading...
        </c:when>
        <c:otherwise>
          <div class="cloudProfileContent">
            <c:choose>
              <c:when test="${profileInfo.hasErrors}">
                <p style="padding-left:1em;">No images were found due to an error.</p>
              </c:when>
              <c:when test="${not profileInfo.profile.enabled}">
                <p style="padding-left:1em;">Cloud profile is disabled.</p>
              </c:when>
              <c:when test="${empty profileInfo.images}">
                <p style="padding-left:1em;">No images were found.</p>
              </c:when>
              <c:otherwise>
                <c:forEach items="${profileInfo.images}" var="image">
                  <bs:changeRequest key="profileInfo" value="${profileInfo}">
                  <bs:changeRequest key="image" value="${image}">
                    <jsp:include page="cloud-list-image.jsp"/>
                  </bs:changeRequest>
                  </bs:changeRequest>
                </c:forEach>
              </c:otherwise>
            </c:choose>
          </div>
        </c:otherwise>
      </c:choose>
    </div>
    <script type="text/javascript">
      <l:blockState blocksType="${cloudProfileId}"/>
      BS.CollapsableBlocks.registerBlock(new BS.BlocksWithHeader('profile${profileInfo.id}'), 'agentCloudProfileList');
    </script>
  </c:forEach>
  <c:if test="${empty form.selfProfiles}">
    <authz:authorize allPermissions="MANAGE_AGENT_CLOUDS">
      <div>Cloud profile settings can be specified on the <a href="<c:url value="/admin/editProject.html?projectId=_Root&tab=clouds"/>"
      >project clouds configuration page</a>.
      </div>
    </authz:authorize>
  </c:if>

