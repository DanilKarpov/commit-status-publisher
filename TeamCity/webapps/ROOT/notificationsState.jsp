<%@include file="/include-internal.jsp" %>
<%--@elvariable id="anyEventWatched" type="java.lang.Boolean"--%>
<%--@elvariable id="notificatorsState" type="java.util.Map<java.lang.String, jetbrains.buildServer.controllers.profile.notifications.NotificationsInfoController.NotificatorState>"--%>
<%--@elvariable id="buildType" type="jetbrains.buildServer.serverSide.SBuildType"--%>
<%--@elvariable id="project" type="jetbrains.buildServer.serverSide.SProject"--%>

<bs:linkScript>
  /js/bs/notificationRules.js
</bs:linkScript>
<bs:linkCSS>
  /css/notificationRules.css
</bs:linkCSS>

<style type="text/css">
  .icon-bell-half {
    position: relative;
    display: inline-block;
    width: 10px;
    height: 10px;
  }

  .icon-bell-half :last-child {
    width: 6px;
    overflow: hidden;
  }

  .icon-bell-half * {
    position: absolute;
  }
</style>

<c:set var="item" value="${empty buildType ? 'Project' : 'Build Configuration'}"/>
<c:set var="hasRule" value="${anyNotifierHasGlobalRule or hasChangesHere}"/>

<span class="" id="userNotificationsState" onmouseover="if(!window.event) window.event = event;BS.bindPopup(this, 'simplePopup');"
><span class="pc__label"><span class="pc__toggle-wrapper toggle" style="padding-right: 6px">
  <c:choose>
    <c:when test="${anyEventWatched}">
      <c:choose>
        <c:when test="${hasRule}">
          <a href="profile.html?item=userNotifications&details=1&filter=${filter}&filterType=${filterType}" class="icon-bell-alt noUnderline"></a>
        </c:when>
        <c:otherwise>
          <span class="icon-bell-half">
            <a href="profile.html?item=userNotifications&details=1&filter=${filter}&filterType=${filterType}" class="icon-bell noUnderline"></a>
            <a href="profile.html?item=userNotifications&details=1&filter=${filter}&filterType=${filterType}" class="icon-bell-alt noUnderline"></a>
          </span>
        </c:otherwise>
      </c:choose>
    </c:when>
    <c:otherwise>
      <a href="profile.html?item=userNotifications&details=1&filter=${filter}&filterType=${filterType}" class="icon-bell noUnderline"></a>
    </c:otherwise>
  </c:choose>
</span></span></span>
<div class="popupDiv" id="userNotificationsStateContent">
  <div class="popupBody">
    <div>
      <c:choose>
        <c:when test="${not anyEventWatched}">You don't have notification rules configured for this <c:out value="${item}"/></c:when>
        <c:when test="${not hasRule}">You will be notified when you'll make a commit in this <c:out value="${item}"/> by:</c:when>
        <c:otherwise>You are subscribed to build events in this <c:out value="${item}"/> by:</c:otherwise>
      </c:choose>
    </div>
    <c:if test="${anyEventWatched}">
      <c:forEach var="type" items="${notificatorsState.keySet()}">
        <c:if test="${notificatorsState[type].state}">
          <ul>
            <li><a href="profile.html?notificatorType=${type}&item=userNotifications&filterType=${filterType}&filter=${filter}">${notificatorsState[type].displayName}</a></li>
          </ul>
        </c:if>
      </c:forEach>
    </c:if>
  </div>
</div>
