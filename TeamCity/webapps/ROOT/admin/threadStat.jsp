<%@ include file="/include-internal.jsp" %>
<style type="text/css">
  div.threadStatContainer {
    position: fixed;
    left:0.1em;
    bottom: 1.5em;
    z-index: 1000;
  }
  .threadStatToggle {
    width: 1em;
    cursor: pointer;
    vertical-align: bottom;
    position: fixed;
    left:0.1em;
    bottom: 1em;
  }
  div.threadStat {
    border: 1px solid gray;
    background-color: var(--ring-secondary-background-color, #f7f9fa);
    padding-left: 1em;
    padding-right: 1em;
    padding-top: 0.5em;
    padding-bottom: 0.5em;
    height: 20em;
    overflow-y: scroll;
    display: none;
  }
  .threadStatLevel {
    display: none;
  }
  .threadStatBlock0 {
    margin-left: 1em;
    display: block;
    cursor: pointer;
  }
  .threadStatBlock1 {
    margin-left: 1em;
    display: none;
    cursor: pointer;
  }
</style>
<script type="text/javascript">
  toggleThreadStat = function() {
    $j('#threadStat').toggle();
  };
  toggleThreadStatBlock = function(event, blockId) {
    event.stopPropagation();
    $j('#' + blockId).children('div').toggle();
  };
  openInSeparateWindow = function() {
    var w = window.open();
    var threadStatClone = $j('#threadStatInner').clone(true,true);
    $j(w.document.body).append(threadStatClone);
  };
</script>
<div class="threadStatContainer">
  <table>
    <tr>
      <td class="threadStatToggle" onclick="toggleThreadStat()">
        ...
      </td>
      <td>
        <div id="threadStat" class="threadStat">
          <a href="javascript:;" onclick="openInSeparateWindow();">Open in separate window</a>
          <div id="threadStatInner">
            <c:set var="i" value="0"/>
            <c:set var="currentLevel" value="-1"/>
            <c:forEach items="${threadStat.operations}" var="operation">
              <c:set var="operationLevel" value="${operation.level}"/>
              <c:choose>
                <c:when test="${operationLevel == currentLevel}">
                  </div>
                </c:when>
                <c:when test="${operationLevel < currentLevel}">
                  <c:forEach var="j" begin="${operationLevel}" end="${currentLevel}" step="1">
                    </div>
                  </c:forEach>
                </c:when>
              </c:choose>
              <div class="threadStatBlock${operationLevel == 0 ? 0 : 1}" onclick="toggleThreadStatBlock(event, 'threadStatBlock${i}')" id="threadStatBlock${i}">
                <span class="threadStatLevel"><c:out value="${operation.level}"/></span>
                <span class="threadStatDuration"><c:out value="${util:formatNanos(operation.durationNanos)}"/></span>
                <span class="threadStatDescription"><c:out value="${operation.description}"/></span>
              <c:set var="currentLevel" value="${operationLevel}"/>
              <c:set var="i" value="${i+1}"/>
            </c:forEach>
            <c:if test="${currentLevel != -1}">
              <c:forEach var="j" begin="${0}" end="${currentLevel}" step="1">
                </div>
              </c:forEach>
            </c:if>
          </div>
        </div>
      </td>
    </tr>
  </table>
</div>

