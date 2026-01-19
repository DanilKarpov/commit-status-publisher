<%@include file="/include-internal.jsp" %>
<%@ taglib prefix="intprop" uri="/WEB-INF/functions/intprop" %>

<script type="application/javascript">
  BS.TestServerMode = {
    setEnabled: function(activityId, enabled) {
      BS.ajaxRequest(window['base_uri'] + "/admin/testMode.html", {
        parameters: {
          activityId: activityId,
          enabled: enabled
        },
        onComplete: function (transport) {
          BS.reload(true)
        }
      })
    }
  }
</script>

<div class="attentionComment">
  <bs:buildStatusIcon type="red-sign" className="warningIcon"/>TeamCity Server is running in Test Mode, the following server activity can affect state of the external systems:
  <ul>
    <c:forEach items="${activities}" var="activity">
      <li>
        <c:out value="${activity.description}"/>
        <c:choose>
          <c:when test="${activity.enabled}">
            (<span style="color: #0c7523">enabled</span>, <a href="#" onclick="BS.TestServerMode.setEnabled('${activity.id}', false)">disable</a>)
          </c:when>
          <c:otherwise>
            (<span style="color: #a90f1a">disabled</span>, <a href="#" onclick="BS.TestServerMode.setEnabled('${activity.id}', true)">enable</a>)
          </c:otherwise>
        </c:choose>
      </li>
    </c:forEach>
  </ul>
</div>
