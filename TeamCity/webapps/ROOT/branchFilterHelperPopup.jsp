<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="props" uri="http://www.springframework.org/tags/form" %>
<%@include file="/include-internal.jsp"%>

<style type="text/css">

  #branchFilterTabs {
    display: inline-flex;
    border-bottom: 1px solid lightgray;
  }

  #branchFilterTabs .tabOption {
    text-align: center;
    cursor: pointer;
    position: relative;
    white-space: nowrap;
    padding-bottom: 5px;
    padding-top: 5px;
    padding-left: 10px;
  }

  #branchFilterTabs .tabOption.firstTab {
    padding-left: 0px;
  }

  .helperButtonBlock {
    margin-top: 15px;
  }

  .helperButtonBlock .btn.submitButton {
    margin-right: 10px;
  }

  .helperButtonBlock .btn.cancel {
    margin-right: 0px;
  }

  .underline {
    height: 2px;
    width: 0;
    background-color: black;
    transition: width 0.1s ease;
    margin-bottom: -6px;
  }

</style>

<script type="javascript">
  document.addEventListener('click', function (event) {
    var triggerHelperPopup = document.getElementById("branchFilterHelperPopup");
    if (triggerHelperPopup != null) {
      var isClickedInsidePopup = triggerHelperPopup.contains(event.target);
      // do not close when clicked on parameters popup
      var isClickedOnOpenedPopup = event.target.closest('.ui-autocomplete');

      if (!isClickedOnOpenedPopup && !isClickedInsidePopup) {
        triggerHelperPopup.style.display = 'none';
      }
    }
  });
  BS.BranchFilterHelperPopup.updateTabs = function(selected) {
      var underlineId = selected + "Underline";
      var tabContentId = selected + "FilterContainerId";
      for (let elem of document.getElementsByClassName("tabContent")) {
        if (elem.id === tabContentId) {
          $(elem.id).show();
        } else {
          $(elem.id).hide();
        }
      }

      for (let elem of document.getElementsByClassName("underline")) {
        if (elem.id === underlineId) {
          $(elem.id).style.width = "100%";
        } else {
          $(elem.id).style.width = "0%";
        }
      }
    }
</script>

<div id="branchFilterTabs">
  <c:forEach var="tab" items="${tabs}" varStatus="pos">
    <div class="${pos.first ? "tabOption firstTab" : "tabOption"}" onclick="BS.BranchFilterHelperPopup.updateTabs('${tab.getId()}')">
      <span>${tab.getDisplayName()}</span>
      <div id="${tab.getId()}Underline" class="underline" style="width: ${pos.first ? "100%" : "0%"}"></div>
    </div>
  </c:forEach>
</div>

<c:forEach var="tab" items="${tabs}" varStatus="pos">
  <div id="${tab.getId()}FilterContainerId" class="tabContent" style="padding-top: 5px; ${pos.first ? "" : "display: none;"}">
    <jsp:include page="${tab.getJspPath()}"/>
  </div>
</c:forEach>