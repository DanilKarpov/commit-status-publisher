<%@include file="/include-internal.jsp" %>

<script type="text/javascript">
  BS.ExperimentalFeatures = {
    url: window['base_uri'] + "/admin/action.html",
    changeFeatureState: function (featureName, enabled) {
      BS.ajaxRequest(BS.ExperimentalFeatures.url, {
        parameters: "&actionName=" + (enabled ? 'enableFeature' : 'disableFeature') + '&featureName=' + featureName,
        onComplete: function () {
          BS.reload(true);
        }
      })
    }
  }
</script>
<style type="text/css">
  .icon.disabledIcon {
    color: #acaeb2;
  }
</style>

<bs:messages key="experimentalFeaturesMessages"/>
<c:set var="canChangeSettings" value="${afn:permissionGrantedGlobally('MANAGE_EXPERIMENTAL_FEATURES')}"/>

<div>
  <table class="settings runnerFormTable" style="width: 80%">
    <%--@elvariable id="features" type="java.util.List<jetbrains.buildServer.serverSide.features.ExperimentalFeature>"--%>
    <c:forEach items="${features}" var="f" varStatus="pos">
      <c:set var="name" value="${f.name}"/>
      <c:set var="displayName" value="${f.displayName}"/>
      <c:set var="featureDescription" value="${f.description}"/>
      <c:set var="enabled" value="${f.enabled}"/>

      <c:choose>
        <c:when test="${canChangeSettings}">
          <c:set var="cursorStyle" value="cursor: pointer"/>
          <c:choose>
            <c:when test="${enabled}">
              <c:set var="onClick">BS.ExperimentalFeatures.changeFeatureState('<bs:escapeForJs text="${name}"/>', false);</c:set>
              <c:set var="iconStyle" value="icon icon-check"/>
            </c:when>
            <c:otherwise>
              <c:set var="onClick">BS.ExperimentalFeatures.changeFeatureState('<bs:escapeForJs text="${name}"/>', true);</c:set>
              <c:set var="iconStyle" value="icon icon-check-empty"/>
            </c:otherwise>
          </c:choose>
        </c:when>
        <c:otherwise>
          <c:set var="cursorStyle" value=""/>
          <c:set var="onClick" value=""/>
          <c:choose>
            <c:when test="${enabled}">
              <c:set var="iconStyle" value="icon icon-check disabledIcon"/>
            </c:when>
            <c:otherwise>
              <c:set var="iconStyle" value="icon icon-check-empty disabledIcon"/>
            </c:otherwise>
          </c:choose>
        </c:otherwise>
      </c:choose>

      <tr>
        <td>
          <div>
            <span href="#" class="${iconStyle}" title="${f.displayName}" style="${cursorStyle}" onclick="${onClick}; event.stopPropagation();"></span>
            <span style="margin-left: 0.2em; ${cursorStyle}" onclick="${onClick}; event.stopPropagation();"><c:out value="${displayName}"/></span>
          </div>
          <div>
            <span class="grayNote" style="margin-left: 1.6em">${featureDescription}</span>
          </div>
        </td>
      </tr>
    </c:forEach>
  </table>
</div>

